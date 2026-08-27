# ntfy-signal-bridge

Forwards messages from a self-hosted [ntfy](https://ntfy.sh) server to a Signal group. Runs as two pods on a Kubernetes cluster: a subscriber pod (this image) and a [signal-cli](https://github.com/bbernhard/signal-cli-rest-api) daemon pod.

The subscriber receives messages from ntfy over WebSocket and forwards each one to Signal via the signal-cli REST API.

---

## Device link procedure

Run this on first setup, or any time the signal-cli PVC is lost.

The signal-cli daemon links as a secondary device on your Signal account. Your phone number stays on the phone.

### Prepare

1. Confirm the `signal-cli` pod is running:
   ```
   kubectl -n ntfy get deploy/signal-cli
   ```

2. Open a port-forward to the daemon:
   ```
   kubectl -n ntfy port-forward deploy/signal-cli 8080:8080
   ```

### Link

1. Open a browser on your laptop and go to:
   ```
   http://localhost:8080/v1/qrcodelink?device_name=signal-bridge
   ```

2. Open Signal on the iPhone. Go to **Settings → Linked Devices → Link New Device**. Scan the QR code.

3. Confirm the iPhone lists a device named `signal-bridge`.

4. Close the port-forward.

### Collect group IDs

After linking, list groups so you can map ntfy topics to Signal groups:

1. Reopen the port-forward:
   ```
   kubectl -n ntfy port-forward deploy/signal-cli 8080:8080
   ```

2. Trigger a receive to sync group membership:
   ```
   curl -s http://localhost:8080/v1/receive/<account-number>
   ```

3. List groups:
   ```
   curl -s http://localhost:8080/v1/groups/<account-number> | jq '.[] | {id, name}'
   ```

4. Store each group ID you need in Ansible Vault.

5. Close the port-forward.

### Re-linking after a lost device

If the account is already linked on the cluster but something went wrong, delete the stale device from the iPhone first: **Settings → Linked Devices** → tap `signal-bridge` → **Remove**. Then follow the procedure above from the beginning.

---

## Upgrade procedure

Signal-cli releases older than three months can stop working. Check for a new release monthly.

1. Take a snapshot of the `signal-cli-data` PVC before upgrading.
2. Update the `signal-cli` image tag in your deployment to the new version.
3. Redeploy the `signal-cli` pod.
4. Send a test message and confirm it arrives in the Signal group.

**Rollback:** revert the image tag and redeploy. If the Signal session is corrupted after the upgrade, restore the PVC snapshot and redeploy.

---

## Adding a new topic

1. Create a Signal group on the phone for the new topic.

2. Port-forward to the daemon and list groups to get the new group ID:
   ```
   kubectl -n ntfy port-forward deploy/signal-cli 8080:8080
   curl -s http://localhost:8080/v1/groups/<account-number> | jq '.[] | {id, name}'
   ```

3. Store the group ID securely in your deployment configuration.

4. Add the topic to the ntfy `client.yml` subscriber config:
   ```yaml
   subscribe:
     - topic: existing-topic
       command: '/opt/forward.sh "$GROUP_EXISTING"'
     - topic: new-topic
       command: '/opt/forward.sh "$GROUP_NEW_TOPIC"'
   ```

5. Add the group ID as an environment variable in the `signal-bridge` pod.

6. Redeploy the `signal-bridge` pod to pick up the new config.

---

## Recovery — lost PVC

The PVC holds the signal-cli account keys. A lost PVC means the daemon can no longer send messages.

1. Remove the stale linked device from the iPhone: **Settings → Linked Devices** → tap `signal-bridge` → **Remove**.
2. Follow the device link procedure above.
3. Group IDs are not stored on the PVC — existing groups and vault values remain valid.
