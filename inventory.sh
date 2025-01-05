#!/bin/bash

# Global Variables
DEPO_FILE="depo.csv"
KULLANICI_FILE="kullanici.csv"
LOG_FILE="log.csv"
CURRENT_USER=""
CURRENT_ROLE=""

# Ensure necessary files exist
initialize_files() {
    [ ! -f "$DEPO_FILE" ] && touch "$DEPO_FILE"
    [ ! -f "$KULLANICI_FILE" ] && touch "$KULLANICI_FILE" && add_dummy_users
    [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"
}

add_dummy_users() {
    if [ ! -s "$KULLANICI_FILE" ]; then
        echo "ID,AdSoyad,Rol,Parola" > "$KULLANICI_FILE"
        echo "1,admin,Yonetici,$(echo -n 'admin123' | md5sum | awk '{print $1}')" >> "$KULLANICI_FILE"
        echo "2,user1,Kullanici,$(echo -n 'user123' | md5sum | awk '{print $1}')" >> "$KULLANICI_FILE"
        echo "3,user2,Kullanici,$(echo -n 'password' | md5sum | awk '{print $1}')" >> "$KULLANICI_FILE"
        echo "4,user3,Kullanici,$(echo -n '123456' | md5sum | awk '{print $1}')" >> "$KULLANICI_FILE"
        zenity --info --text="Dummy kullanıcılar başarıyla oluşturuldu."
    else
        zenity --info --text="kullanici.csv zaten mevcut, dummy kullanıcılar eklenmedi."
    fi
}

# Log errors
log_error() {
    local message="$1"
    echo "$(date) - ERROR - $message" >> "$LOG_FILE"
}

# Show main menu
show_main_menu() {
    local choice
    if [ "$CURRENT_ROLE" == "Yonetici" ]; then
        choice=$(zenity --list --title="Ana Menü" --column="İşlem" \
            "Ürün Ekle" "Ürün Listele" "Ürün Güncelle" "Ürün Sil" "Rapor Al" \
            "Kullanıcı Yönetimi" "Program Yönetimi" "Çıkış")
    else
        choice=$(zenity --list --title="Ana Menü" --column="İşlem" \
            "Ürün Listele" "Rapor Al" "Çıkış")
    fi

    case $choice in
        "Ürün Ekle") add_product ;;
        "Ürün Listele") list_products ;;
        "Ürün Güncelle") update_product ;;
        "Ürün Sil") delete_product ;;
        "Rapor Al") generate_report ;;
        "Kullanıcı Yönetimi") manage_users ;;
        "Program Yönetimi") manage_program ;;
        "Çıkış") exit_program ;;
        *) zenity --error --text="Geçersiz seçim." ;;
    esac
}

# Authenticate user
authenticate_user() {
    local username password
    username=$(zenity --entry --title="Giriş" --text="Kullanıcı Adı:") || exit
    password=$(zenity --password --title="Giriş") || exit

    while IFS="," read -r id name role hash
    do
	if [[ "$name" == "$username" && "$hash" == "$(echo -n "$password" | md5sum | awk '{print $1}')" ]]; then
            CURRENT_USER="$name"
            CURRENT_ROLE="$role"
            zenity --info --text="Giriş başarılı!"
            return
        fi
    done < "$KULLANICI_FILE"

    zenity --error --text="Hatalı kullanıcı adı veya şifre."
    log_error "Başarısız giriş denemesi: $username"
    exit
}

# Add a product
add_product() {
    if [ "$CURRENT_ROLE" != "Yonetici" ]; then
        zenity --error --text="Bu işlem için yetkiniz yok."
        return
    fi

    local name stock price category
    IFS="|" read -r name stock price category < <(zenity --forms --title="Ürün Ekle" \
        --text="Yeni ürün bilgilerini girin:" \
        --add-entry="Ürün Adı" \
        --add-entry="Stok Miktarı" \
        --add-entry="Birim Fiyatı" \
        --add-entry="Kategori") || return

    # Validate inputs
    if [[ -z "$name" || -z "$stock" || -z "$price" || -z "$category" || "$stock" -lt 0 || "$price" -lt 0 ]]; then
        zenity --error --text="Geçersiz giriş."
        log_error "Ürün ekleme hatası: Geçersiz giriş."
        return
    fi

    # Check for duplicate product name
    if grep -q "$name" "$DEPO_FILE"; then
        zenity --error --text="Bu ürün adıyla başka bir kayıt bulunmaktadır. Lütfen farklı bir ad giriniz."
        log_error "Ürün ekleme hatası: $name adı zaten mevcut."
        return
    fi

    # Generate unique product ID
    local id=$(( $(tail -n 1 "$DEPO_FILE" | cut -d"," -f1) + 1 ))

    # Write to file
    echo "$id,$name,$stock,$price,$category" >> "$DEPO_FILE"
    zenity --info --text="Ürün başarıyla eklendi."
}

# List products
list_products() {
    if [ ! -s "$DEPO_FILE" ]; then
        zenity --info --text="Envanterde ürün bulunmamaktadır."
        return
    fi

    zenity --text-info --title="Ürün Listele" --filename="$DEPO_FILE"
}

# Update a product
update_product() {
    if [ "$CURRENT_ROLE" != "Yonetici" ]; then
        zenity --error --text="Bu işlem için yetkiniz yok."
        return
    fi

    local name new_stock new_price
    name=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün adını girin:") || return

    # Find the product in the file
    if ! grep -q "$name" "$DEPO_FILE"; then
        zenity --error --text="Ürün bulunamadı."
        log_error "Ürün güncelleme hatası: $name bulunamadı."
        return
    fi

    IFS="|" read -r new_stock new_price < <(zenity --forms --title="Ürün Güncelle" \
        --text="Yeni bilgileri girin:" \
        --add-entry="Yeni Stok Miktarı" \
        --add-entry="Yeni Birim Fiyatı") || return

    # Validate inputs
    if [[ "$new_stock" -lt 0 || "$new_price" -lt 0 ]]; then
        zenity --error --text="Geçersiz giriş."
        log_error "Ürün güncelleme hatası: Geçersiz giriş."
        return
    fi

    # Update the product
    sed -i "/$name/s/.*/$(grep "$name" "$DEPO_FILE" | awk -F"," -v s="$new_stock" -v p="$new_price" '{print $1","$2","s","p","$5}')/" "$DEPO_FILE"
    zenity --info --text="Ürün başarıyla güncellendi."
}

# Delete a product
delete_product() {
    if [ "$CURRENT_ROLE" != "Yonetici" ]; then
        zenity --error --text="Bu işlem için yetkiniz yok."
        return
    fi

    local name
    name=$(zenity --entry --title="Ürün Sil" --text="Silmek istediğiniz ürünün adını girin:") || return

    # Confirm deletion
    zenity --question --text="Ürünü silmek istediğinize emin misiniz?"
    if [ $? -ne 0 ]; then
        return
    fi

    # Delete the product
    if ! grep -q "$name" "$DEPO_FILE"; then
        zenity --error --text="Ürün bulunamadı."
        log_error "Ürün silme hatası: $name bulunamadı."
        return
    fi

    sed -i "/$name/d" "$DEPO_FILE"
    zenity --info --text="Ürün başarıyla silindi."
}

# Report Generation
generate_report() {
  local choice=$(zenity --list --title="Rapor Al" --column="Rapor Türü" \
    "Stokta Azalan Ürünler" "En Yüksek Stok Miktarına Sahip Ürünler")

  case "$choice" in
    "Stokta Azalan Ürünler")
      local threshold=$(zenity --entry --title="Eşik Değeri" --text="Eşik değerini girin:")
      awk -F ',' -v threshold="$threshold" 'BEGIN {print "Stokta Azalan Ürünler:"} $3 < threshold {print $2 " - Stok: " $3}' "$DEPO_FILE" | zenity --text-info --title="Stokta Azalan Ürünler"
      ;;
    "En Yüksek Stok Miktarına Sahip Ürünler")
      awk -F ',' 'BEGIN {print "En Yüksek Stok Miktarına Sahip Ürünler:"} {if ($3 > max) {max=$3; name=$2}} END {print name " - Stok: " max}' "$DEPO_FILE" | zenity --text-info --title="En Yüksek Stok Miktarı"
      ;;
  esac
}

# User Management
manage_users() {
  local choice=$(zenity --list --title="Kullanıcı Yönetimi" --column="İşlem" \
    "Yeni Kullanıcı Ekle" "Kullanıcıları Listele" "Kullanıcı Güncelle" "Kullanıcı Sil")

  case "$choice" in
    "Yeni Kullanıcı Ekle")
      local input=$(zenity --forms --title="Yeni Kullanıcı Ekle" --text="Kullanıcı bilgilerini girin:" \
        --add-entry="Ad Soyad" \
        --add-entry="Rol" \
        --add-password="Parola")
      IFS='|' read -r name role password <<< "$input"
      
      # Dosyadaki en son satırı alıp ID'yi bir artırarak yeni ID'yi bulma
      local last_id=$(tail -n 1 "$KULLANICI_FILE" | cut -d ',' -f 1)
      local new_id=$((last_id + 1))  # Yeni ID'yi hesaplama
      
      # MD5 ile şifreyi şifreleme
      local hashed_password=$(echo -n "$password" | md5sum | awk '{print $1}')
      
      # Kullanıcıyı dosyaya ekleme
      echo "$new_id,$name,$role,$hashed_password" >> "$KULLANICI_FILE"
      zenity --info --text="Kullanıcı başarıyla eklendi."
      ;;
      
    "Kullanıcıları Listele")
      zenity --text-info --title="Kullanıcı Listesi" --filename="$KULLANICI_FILE"
      ;;
      
    "Kullanıcı Güncelle")
      local user_id=$(zenity --entry --title="Kullanıcı Güncelle" --text="Güncellemek istediğiniz kullanıcının ID'sini girin:")
      local new_password=$(zenity --entry --title="Yeni Parola" --text="Yeni parolayı girin:")
      
      # MD5 ile yeni şifreyi şifreleme
      local hashed_password=$(echo -n "$new_password" | md5sum | awk '{print $1}')
      
      # Kullanıcıyı ID'ye göre güncelleme
      awk -F ',' -v id="$user_id" -v hashed_password="$hashed_password" 'BEGIN {OFS=","} $1 == id { $4 = hashed_password } {print $0}' "$KULLANICI_FILE" > tmp.csv && mv tmp.csv "$KULLANICI_FILE"
      zenity --info --text="Kullanıcı başarıyla güncellendi."
      ;;
      
    "Kullanıcı Sil")
      local user_id=$(zenity --entry --title="Kullanıcı Sil" --text="Silmek istediğiniz kullanıcının ID'sini girin:")
      
      # Kullanıcıyı ID'ye göre silme
      awk -F ',' -v id="$user_id" 'BEGIN {OFS=","} $1 != id {print $0}' "$KULLANICI_FILE" > tmp.csv && mv tmp.csv "$KULLANICI_FILE"
      zenity --info --text="Kullanıcı başarıyla silindi."
      ;;
  esac
}


# Program Management
manage_program() {
  local choice=$(zenity --list --title="Program Yönetimi" --column="İşlem" \
    "Diskte Kapladığı Alan" "Diske Yedek Alma" "Hata Kayıtlarını Görüntüleme")

  case "$choice" in
    "Diskte Kapladığı Alan")
      local disk_usage=$(du -sh . | awk '{print $1}')
      zenity --info --text="Dosyaların kapladığı toplam alan: $disk_usage"
      ;;
    "Diske Yedek Alma")
      local backup_file="backup_$(date +%Y%m%d%H%M%S).tar.gz"
      tar -czf "$backup_file" "$DEPO_FILE" "$KULLANICI_FILE" "$LOG_FILE"
      zenity --info --text="Yedekleme tamamlandı. Dosya: $backup_file"
      ;;
    "Hata Kayıtlarını Görüntüleme")
      if [ ! -s "$LOG_FILE" ]; then
        zenity --warning --text="Hata kaydı bulunmamaktadır."
      else
        zenity --text-info --title="Hata Kayıtları" --filename="$LOG_FILE"
      fi
      ;;
  esac
}

# Exit program
exit_program() {
    zenity --question --text="Programdan çıkmak istediğinize emin misiniz?"
    if [ $? -eq 0 ]; then
        exit
    fi
}

# Main
initialize_files
authenticate_user
while true; do
    show_main_menu
done
