#!/bin/bash

# Target File
TARGET="/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🔧 Memulai Uninstall Proteksi Sidebar (Protect 12)..."

# 1. CEK FILE
if [ ! -f "$TARGET" ]; then
    echo "❌ File admin.blade.php tidak ditemukan!"
    exit 1
fi

# 2. BUAT BACKUP SEBELUM UBAH
cp "$TARGET" "${TARGET}.bak_uninstall_${TIMESTAMP}"
echo "📦 Backup file sebelum uninstall disimpan di: ${TARGET}.bak_uninstall_${TIMESTAMP}"

# 3. HAPUS PROTEKSI
# Menghapus blok kode mulai dari START-PROTECT sampai END-PROTECT
if grep -q "{{-- START-PROTECT --}}" "$TARGET"; then
    sed -i '/{{-- START-PROTECT --}}/,/{{-- END-PROTECT --}}/d' "$TARGET"
    echo "🧹 Kode proteksi berhasil dihapus dari file."
else
    echo "⚠️ Kode proteksi tidak ditemukan, mungkin sudah bersih."
fi

# 4. BERSIHKAN PROTEKSI LAMA (Jaga-jaga jika ada sisa versi sebelumnya)
if grep -q "\[PROTECT-KYXZAN\]" "$TARGET"; then
    sed -i '/\[PROTECT-KYXZAN\]/,/\[END PROTECT-KYXZAN\]/d' "$TARGET"
    echo "🧹 Sisa proteksi lama (versi lama) juga dibersihkan."
fi

# 5. BERSIHKAN CACHE (WAJIB)
echo "🔄 Membersihkan Cache Tampilan..."
php /var/www/pterodactyl/artisan view:clear
php /var/www/pterodactyl/artisan config:clear

echo "✅ UNINSTALL SELESAI!"
echo "🔓 Menu Admin kembali normal dan terlihat untuk semua user admin."