#!/bin/bash

# ==========================================
# SCRIPT PENYEMBUNYI MENU (SAFE FOR CUSTOM THEME)
# Metode: CSS Injection (Tidak merusak layout)
# ==========================================

TARGET="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${TARGET}.bak_safe_${TIMESTAMP}"

echo "🚀 Memulai Inject Proteksi Sidebar (Metode Aman)..."

# 1. Cek apakah file target ada
if [ ! -f "$TARGET" ]; then
    echo "❌ File admin.blade.php tidak ditemukan!"
    exit 1
fi

# 2. Backup dulu file aslinya (Wajib!)
cp "$TARGET" "$BACKUP_PATH"
echo "📦 Backup file asli aman di: $BACKUP_PATH"

# 3. Definisikan Kode Inject (Blade + CSS)
# Kita pakai CSS untuk menyembunyikan elemen berdasarkan Link URL-nya
# Ini cara paling aman karena tidak perlu menebak struktur HTML tema custom.

INJECT_CODE='
    {{-- [PROTECT-VEYORA] HIDE MENU FOR NON-ADMIN ID 1 --}}
    @if(Auth::user()->id != 1)
    <style>
      /* Sembunyikan link menu yang mengarah ke halaman sensitif */
      a[href*="/admin/settings"],
      a[href*="/admin/locations"],
      a[href*="/admin/nodes"],
      a[href*="/admin/mounts"],
      a[href*="/admin/nests"] {
          display: none !important;
      }
      
      /* Coba sembunyikan List Item (li) pembungkusnya juga biar rapi (Support Modern Browser) */
      li:has(a[href*="/admin/settings"]),
      li:has(a[href*="/admin/locations"]),
      li:has(a[href*="/admin/nodes"]),
      li:has(a[href*="/admin/mounts"]),
      li:has(a[href*="/admin/nests"]) {
          display: none !important;
      }
    </style>
    @endif
    {{-- [END PROTECT-VEYORA] --}}
'

# 4. Bersihkan inject lama jika pernah dipasang (biar gak double)
sed -i '/\[PROTECT-VEYORA\]/,/\[END PROTECT-VEYORA\]/d' "$TARGET"

# 5. Suntikkan kode baru tepat sebelum tag penutup </head>
# Kita pakai perl karena lebih jago handling multiline dibanding sed biasa
perl -i -pe 's|(</head>)|'"$(echo "$INJECT_CODE" | tr -d '\n')"' \n$1|' "$TARGET"

# 6. Bersihkan Cache View
echo "🧹 Membersihkan cache panel..."
php /var/www/pterodactyl/artisan view:clear

echo "✅ SELESAI!"
echo "🛡️ Menu Settings, Nodes, dll sekarang tersembunyi secara visual untuk selain ID 1."
echo "🎨 TEMA KAMU AMAN (Tidak ditimpa, cuma disuntik CSS)."
