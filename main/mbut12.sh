#!/bin/bash

# Target File
TARGET="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${TARGET}.bak_${TIMESTAMP}"

echo "🔧 Memulai Proteksi Sidebar (KHUSUS HANYA ID 1)..."

# 1. CEK FILE
if [ ! -f "$TARGET" ]; then
    echo "❌ File admin.blade.php tidak ditemukan!"
    exit 1
fi

# 2. BUAT BACKUP (Supaya aman kalau mau restore)
cp "$TARGET" "$BACKUP_PATH"
echo "📦 Backup file asli aman di: $BACKUP_PATH"

# 3. BERSIHKAN PROTEKSI LAMA
# Kita hapus kode inject lama biar gak bentrok
sed -i '/\[PROTECT-VEYORA\]/,/\[END PROTECT-VEYORA\]/d' "$TARGET"
sed -i '/{{-- START-PROTECT --}}/,/{{-- END-PROTECT --}}/d' "$TARGET"

echo "🧹 Script lama sudah dibersihkan."

# 4. BUAT FILE PAYLOAD (LOGIKA STRICT ID=1)
# Perhatikan bagian @if(Auth::user()->id != 1)
cat > /tmp/inject_payload.txt << 'EOF'
{{-- START-PROTECT --}}
{{-- Logika: Jika user ID BUKAN 1, maka load CSS untuk menyembunyikan menu --}}
@if(Auth::user()->id != 1)
<style>
  /* Sembunyikan Menu Sensitif */
  a[href*="/admin/settings"],
  a[href*="/admin/locations"],
  a[href*="/admin/nodes"],
  a[href*="/admin/mounts"],
  a[href*="/admin/nests"] {
      display: none !important;
  }
  
  /* Sembunyikan List Item (ikon + teks) pembungkusnya */
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

# 5. INJECT MENGGUNAKAN PYTHON
# Python menyisipkan kode CSS tepat sebelum tag penutup </head>
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

    # Cek apakah sudah ada
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

# 7. BERSIHKAN CACHE (SANGAT PENTING)
echo "🔄 Membersihkan Cache Tampilan..."
php /var/www/pterodactyl/artisan view:clear
php /var/www/pterodactyl/artisan config:clear

echo "✅ SELESAI!"
echo "🔒 Sekarang menu Settings, Nodes, dll BENAR-BENAR HILANG untuk siapapun KECUALI ID 1."
