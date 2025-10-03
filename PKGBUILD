# Maintainer: Myden <mydenglobal@gmail.com>
pkgname=depender
pkgver=1.0.0
pkgrel=1
pkgdesc="أداة إدارة ملفات .desktop لنظام Daruza"
arch=('any')
url="https://github.com/اسم_المستخدم/depender"
license=('GPL3')
depends=('python')
makedepends=('git')
install='depender.install'

# تحديد مصادر الكود
source=(
    "depender::https://raw.githubusercontent.com/اسم_المستخدم/depender/main/depender"
    "depender.desktop::https://raw.githubusercontent.com/اسم_المستخدم/depender/main/depender.desktop"
    "README.md::https://raw.githubusercontent.com/اسم_المستخدم/depender/main/README.md"
)

# تحقق من التوقيع (اختياري)
# validpgpkeys=('YOUR_GPG_KEY_ID')

sha256sums=(
    'SKIP'
    'SKIP'
    'SKIP'
)

package() {
    # تثبيت ملف الأداة الرئيسي
    install -Dm755 "$srcdir/depender" "$pkgdir/usr/bin/depender"
    
    # تثبيت ملف .desktop
    install -Dm644 "$srcdir/depender.desktop" "$pkgdir/usr/share/applications/depender.desktop"
    
    # إنشاء مجلد التوثيق
    install -dm755 "$pkgdir/usr/share/doc/depender"
    install -m644 "$srcdir/README.md" "$pkgdir/usr/share/doc/depender/README.md"
}

# دالة لتنظيف الملفات المؤقتة
pkgver() {
    cd "$srcdir/$pkgname"
    git describe --tags | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}