# **Uygulama Tanıtımı**

**[Video Tanıtımı](https://www.youtube.com/watch?v=FJPkqaPE8xE)**

**[Repository Linki](https://github.com/adraarda23/linux-zenity)**

Bu uygulama, kullanıcı rolleri ve veri yönetimiyle ilgili fonksiyonlar sunarak ürün ve kullanıcı yönetimi işlemlerini kolaylaştırmak için geliştirilmiştir. Ayrıca, çeşitli raporlama, yedekleme ve disk yönetimi özelliklerine de sahiptir.

---

## **1. Fonksiyonlar**

### **a. Kullanıcı Rolleri**

- **Yönetici**: Tüm işlemleri yönetebilir, kullanıcı ekleyebilir ve silebilir, raporları alabilir ve disk yönetimi yapabilir.
- **Kullanıcı**: Ürünleri listeleyebilir ve güncelleyebilir, ancak yönetici işlemlerini gerçekleştiremez.

### **b. Veri Saklama**

Veriler aşağıdaki dosyalarda saklanır:
- **depo.csv**: Ürünler ve envanter bilgisi.
- **kullanici.csv**: Kullanıcı bilgileri.
- **log.csv**: Uygulama içindeki işlemlerle ilgili hata kayıtları.

---

## **2. Ana Menü**

Ana menüdeki işlemler kullanıcı tipine göre değişiklik gösterir. Aşağıdaki işlemler mevcuttur:

### **i. Ürün Ekle**
Yeni bir ürün eklemek için gerekli bilgileri girin ve ürün veritabanına kaydedin.

### **ii. Ürün Listele**
Mevcut ürünleri görüntüleyin. Ürün listesi, ürün adı, stok miktarı gibi bilgileri içerir.

### **iii. Ürün Güncelle**
Bir ürünü güncellemek için ürünün bilgilerini düzenleyin.

### **iv. Ürün Sil**
Ürünü sistemden silin.

### **v. Rapor Al**
İki farklı rapor alabilirsiniz:
- **Stokta Azalan Ürünler**: Eşik değeri belirleyerek, bu değerin altındaki stok miktarına sahip ürünleri listeleyin.
- **En Yüksek Stok Miktarına Sahip Ürünler**: Eşik değeri belirleyerek, bu değerin üzerinde stok miktarına sahip ürünleri listeleyin.

### **vi. Kullanıcı Yönetimi**

Yönetici kullanıcıları yönetebilir:
- **Yeni Kullanıcı Ekle**: Yeni kullanıcı ekleyin.
- **Kullanıcıları Listele**: Mevcut kullanıcıları listeleyin.
- **Kullanıcı Güncelle**: Kullanıcı bilgilerini güncelleyin.
- **Kullanıcı Silme**: Bir kullanıcıyı sistemden silin.

### **vii. Program Yönetimi**

Yönetici, sistemle ilgili yönetimsel işlemleri gerçekleştirebilir:
- **Diskteki Alanı Göster**: Depolama alanı durumu ve önemli dosyaların (depo.csv, kullanici.csv, log.csv) boyutları gösterilir.
- **Diske Yedekle**: Veritabanı dosyalarını (depo.csv, kullanici.csv) yedekleyin.
- **Hata Kayıtlarını Göster**: Sistemdeki hata kayıtlarını **log.csv** dosyasından görüntüleyin.

### **viii. Çıkış**
Uygulamadan çıkış yapın.

---

## **3. Kullanım**

### **Başlatma**

Uygulamayı çalıştırmak için aşağıdaki komutları sırasıyla çalıştırınız:

```bash
git clone https://github.com/adraarda23/linux-zenity.git
cd linux-zenity
chmod +x inventory.sh
./inventory.sh
