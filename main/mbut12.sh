#!/bin/bash

# Target File
TARGET="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${TARGET}.bak_${TIMESTAMP}"  # <--- INI NAMA FILE BACKUPNYA

echo "🔧 Memulai Perbaikan Smart Sidebar..."

# 1. CEK FILE
if [ ! -f "$TARGET" ]; then
    echo "❌ File admin.blade.php tidak ditemukan!"
    exit 1
fi

# 2. BUAT BACKUP (PENTING!)
# Kita copy dulu file aslinya sebelum diedit-edit
cp "$TARGET" "$BACKUP_PATH"
echo "📦 Backup file asli aman di: $BACKUP_PATH"

# 3. BERSIHKAN PROTEKSI LAMA
# Kita hapus blok kode [PROTECT-VEYORA] atau sisa-sisa script sebelumnya
sed -i '/\[PROTECT-VEYORA\]/,/\[END PROTECT-VEYORA\]/d' "$TARGET"
sed -i '/{{-- START-PROTECT --}}/,/{{-- END-PROTECT --}}/d' "$TARGET"

echo "🧹 Script lama/sampah sudah dibersihkan."

# 4. DEFINISI KODE BARU (ANTI ERROR)
# Cek: Jika BUKAN Root Admin (!auth()->user()->root_admin), sembunyikan menu.
INJECT_CONTENT='
{{-- START-PROTECT --}}
@if(!auth()->user()->root_admin)
<style>
  /* Sembunyikan Menu Sensitif untuk Non-Root Admin */
  a[href*="/admin/settings"],
  a[href*="/admin/locations"],
  a[href*="/admin/nodes"],
  a[href*="/admin/mounts"],
  a[href*="/admin/nests"] {
      display: none !important;
  }
  
  /* Sembunyikan List Item pembungkusnya (CSS Modern) */
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
'

# 5. SUNTIKKAN KODE KE DALAM <HEAD>
# Menyisipkan kode CSS tepat sebelum tag penutup </head>
perl -i -pe 's|(</head>)|'"$(echo "$INJECT_CONTENT" | tr -d '\n')"' \n$1|' "$TARGET"

# 6. BERSIHKAN CACHE (WAJIB)
echo "🔄 Refreshing Panel Cache..."
php /var/www/pterodactyl/artisan view:clear
php /var/www/pterodactyl/artisan config:clear

echo "✅ SELESAI! Coba cek panel sekarang."
echo "ℹ️  Logika baru: Menu hanya muncul untuk ROOT ADMIN (Pemilik)."
