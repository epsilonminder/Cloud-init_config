# ProxmoxでCloud-Init対応Ubuntuテンプレートを作る手順（CLI中心）
※　このコードはChatGPTで作成していますが、実際に動作確認していますので、おおむね動くと思います

# 💡 目的

Proxmox GUIから簡単にCloud-Init対応のUbuntu VMをクローン・作成できるテンプレートを用意する。

---

## ✅ 事前準備

- Proxmox上で操作するノード（例: `Prox_node1`）を決める
- `working` というマウント済みストレージがある前提

---

## 1. Ubuntu Cloud-Init対応イメージのダウンロード

Ubuntu公式から最新のcloudimgを取得（例：Ubuntu 24.04 Noble）

```jsx
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img \\
     -P /mnt/pve/working/template/iso/
```

## 2. 新しいVMを作成（ディスクなし）

```jsx
qm create 9000 --name ubuntu24-cloud --memory 2048 --net0 virtio,bridge=vmbr0
```

## 3. ディスクをインポート

```jsx
qm importdisk 9000 /mnt/pve/working/template/iso/noble-server-cloudimg-amd64.img working
```

## 4. インポートされたディスクをアタッチ

```jsx
qm set 9000 --scsihw virtio-scsi-pci --scsi0 working:9000/vm-9000-disk-0.raw
```

## 5. Cloud-Initディスクを追加

```jsx
qm set 9000 --ide2 local-lvm:cloudinit
```

## 6. ブートデバイス・コンソール設定

```jsx
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
```

なお、ここの出力をシリアルコンソールにしたくないときはvgaの引数をstdにしておくのがよい（らしい）が、
私の観測範囲では、ここをserialにしていてもnoVNCやxterm.jsは動きそう。

## 7. オプション：DNS設定（DHCPにDNSが含まれない環境向け

```jsx
qm set 9000 --nameserver 8.8.8.8 --searchdomain localdomain
```

## 8. テンプレート化

```jsx
qm template 9000
```

これで VM 9000 が Cloud-Init 対応のテンプレートに変わる。

# 🧪 テスト：GUIからのVM作成手順

ProxmoxのGUIでVM 9000（テンプレート）を右クリック → 「クローン」
任意のVM名とIDを設定して作成
作成されたVMを選択 → 「Cloud-Init」タブで：

- ユーザー名（例：ubuntu）
- パスワード
- IPアドレス（例：DHCP）
- DNS設定（必要なら)

起動＆コンソールでログイン確認！

## 📝 備考

イメージは .img 形式の QCOW2 / RAW を使う（cloudimg）
working, local-lvm は環境に応じて変更可
他のOS（Debian, Rockyなど）でも同様の流れで対応可能

## 🎉 まとめ
これでProxmox上にCloud-Init対応テンプレートが完成！
以後はGUIからクローンして数クリックでVM作成・起動可能🎊

# 参考:

## Proxmoxで入力するコード一覧

```bash
qm create 9000 --name ubuntu24-cloud --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 /mnt/pve/working/template/iso/noble-server-cloudimg-amd64.img working
qm set 9000 --scsihw virtio-scsi-pci --scsi0 working:vm-9000-disk-0
qm config 9000
qm template 9000
qm move_disk 9000 scsi0 local-lvm --delete
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --nameserver 1.1.1.1 --searchdomain localdomain
qm set 9000 --ciuser youruser --cipassword yourpass
qm set 9000 --ipconfig0 ip=dhcp
```
