# Maintainer: Your Name <your_email@example.com>
pkgname=depender
pkgver=1.0.0
pkgrel=1
pkgdesc="Desktop File Management Tool for Desind"
arch=('any')
url="https://github.com/MdX07r/Depender"
license=('GPL3')
depends=('python')
makedepends=('git')
install='depstall.sh'

# Source files
source=(
    "depender::https://raw.githubusercontent.com/MdX07r/Depender/main/dli.py"
    "depender.desktop::https://raw.githubusercontent.com/MdX07r/Depender/main/depender.desktop"
    "README.md::https://raw.githubusercontent.com/MdX07r/Depender/main/README.md"
)

sha256sums=(
    'SKIP'
    'SKIP'
    'SKIP'
)

package() {
    # Install the main tool
    install -Dm755 "$srcdir/depender" "$pkgdir/usr/bin/dli.py"
    
    # Install the desktop file
    install -Dm644 "$srcdir/depender.desktop" "$pkgdir/usr/share/applications/depender.desktop"
    
    # Create documentation directory
    install -dm755 "$pkgdir/usr/share/doc/depender"
    install -m644 "$srcdir/README.md" "$pkgdir/usr/share/doc/depender/README.md"
}

# Function to clean up temporary files
pkgver() {
    cd "$srcdir/$pkgname"
    git describe --tags | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}


