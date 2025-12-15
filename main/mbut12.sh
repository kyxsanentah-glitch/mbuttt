#!/bin/bash

# Target File
TARGET="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${TARGET}.bak_${TIMESTAMP}"

echo "🔧 Memulai Perbaikan Sidebar (Metode Python Anti-Error)..."

# 1. CEK FILE
if [ ! -f "$TARGET" ]; then
    echo "❌ File admin.blade.php tidak ditemukan!"
    exit 1
fi

# 2. BUAT BACKUP (SAFE MODE)
cp "$TARGET" "$BACKUP_PATH"
echo "📦 Backup file asli aman di: $BACKUP_PATH"

# 3. BERSIHKAN PROTEKSI LAMA (PENTING)
# Kita hapus blok kode bekas script sebelumnya biar bersih
sed -i '/\[PROTECT-VEYORA\]/,/\[END PROTECT-VEYORA\]/d' "$TARGET"
sed -i '/{{-- START-PROTECT --}}/,/{{-- END-PROTECT --}}/d' "$TARGET"

echo "🧹 Script lama/sampah sudah dibersihkan."

# 4. BUAT FILE PAYLOAD SEMENTARA
# Kita tulis kodenya ke file dulu biar gak error saat dibaca
cat > /tmp/inject_payload.txt << 'EOF'
{{-- START-PROTECT --}}
@if(!auth()->user()->root_admin)
<style>
  /* Sembunyikan Menu untuk Non-Root Admin */
  a[href*="/admin/settings"],
  a[href*="/admin/locations"],
  a[href*="/admin/nodes"],
  a[href*="/admin/mounts"],
  a[href*="/admin/nests"] {
      display: none !important;
  }
  
  li:has(a[href*="/admin/settings"]),
  li:has(a[href*="/admin/locations"]),
  li:has(a[href*="/admin/nodes"]),
  li:has(a[href*="/admin/mounts"]),
  li:has(a[href*="/admin/nests"]) {
      display: none !important;
  }
</style>
@endif
{{-- END-PROTECT --}}
EOF

# 5. INJECT MENGGUNAKAN PYTHON (LEBIH KUAT)
# Python akan membaca file target, mencari </head>, dan menyisipkan payload sebelumnya.
python3 -c "
import sys
import os

target_file = '$TARGET'
payload_file = '/tmp/inject_payload.txt'

try:
    with open(payload_file, 'r') as f:
        payload = f.read()
    
    with open(target_file, 'r') as f:
        content = f.read()

    # Cek apakah sudah ada (double check)
    if 'START-PROTECT' not in content:
        # Ganti </head> dengan payload + </head>
        new_content = content.replace('</head>', payload + '\n</head>')
        
        with open(target_file, 'w') as f:
            f.write(new_content)
        print('✅ Inject Kode Berhasil!')
    else:
        print('⚠️ Kode sudah ada, skip inject.')

except Exception as e:
    print(f'❌ Error Python: {e}')
    sys.exit(1)
"

# 6. BERSIHKAN SISA
rm /tmp/inject_payload.txt

# 7. BERSIHKAN CACHE (WAJIB)
echo "🔄 Refreshing Panel Cache..."
php /var/www/pterodactyl/artisan view:clear
php /var/www/pterodactyl/artisan config:clear

echo "✅ SELESAI! Cek panel sekarang."
echo "ℹ️  Menu Settings dll HANYA muncul untuk ROOT ADMIN."
