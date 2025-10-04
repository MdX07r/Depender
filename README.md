# 🌐 Depender - Advanced Application Manager for Desind

[![GitHub license](https://img.shields.io/badge/license-GPLv3-blue.svg)](https://github.com/MdX07r/depender/blob/main/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/MdX07r/depender/pulls)
[![Desind OS Compatible](https://img.shields.io/badge/Desind-Compatible-F1F1F1)](https://github.com/MdX07r/desind)

**Depender** is a powerful command-line tool designed for the **Desind OS** that goes beyond basic application management. It allows you to create custom applications, convert websites into desktop applications, and manage your application ecosystem with ease — all while maintaining lightning-fast performance.

## 🌟 Features

- **🚀 Create Desktop Applications**: Generate `.desktop` files for any executable in seconds
- **🌐 Web to Desktop**: Convert websites into standalone desktop applications with automatic icon detection
- **🔍 Application Management**: List, search, and launch applications with precision filtering
- **🎭 Browser Integration**: Automatically detect browser profiles for isolated web applications
- **🖼️ Smart Icon Detection**: Extract favicons from websites for perfect application icons
- **📊 JSON Output**: Export application lists for programmatic use in scripts
- **⚡️ Lightning Fast**: Built with performance in mind (response time < 5ms)
- **🌍 Multi-Profile Support**: Create web applications with different browser profiles
- **🗑️ Easy Removal**: Cleanly remove applications you no longer need

## 📦 Installation

### 🐧 Linux (Manual Installation)
```bash
sudo ./depstall.sh
```

### 🐧 Arch Linux (AUR)
```bash
yay -S depender
```

### 💻 Windows Subsystem for Linux (WSL)
```bash
git clone https://github.com/MdX07r/depender.git
cd depender
sudo ./depstall.sh
```

## 🚀 Basic Usage

### 1. 📋 List Applications
Display all installed applications:
```bash
depender list
```

Filter by category:
```bash
depender list -c Network
```

Search for applications:
```bash
depender list -s "file"
```

List only web applications:
```bash
depender list -w
```

Output in JSON format:
```bash
depender list -j
```

### 2. ℹ️ View Application Information
Get detailed information about a specific application:
```bash
depender info "Firefox"
```

### 3. ▶️ Launch an Application
Run a specific application:
```bash
depender run "Firefox"
```

### 4. 🔍 Search for Applications
Search for applications based on a query:
```bash
depender search "browser"
```

## 🌈 Advanced Features

### 1. 🌐 Create a Web Application
Convert a website into a desktop application:
```bash
depender create web -u https://web.whatsapp.com -n "WhatsApp Web"
```

Depender will:
- 📝 Fetch the website title as the application name
- 🖼️ Extract the favicon for the application icon
- 📁 Create a proper `.desktop` file in your local applications directory
- 🧪 Isolate the application in its own browser profile

### 2. 🛠️ Create a Custom Application
Create a desktop entry for any command:
```bash
depender create app -n "My App" -e "/path/to/executable" -c "My custom application" -i "my-icon"
```

### 3. 🗑️ Remove an Application
Remove an application by name:
```bash
depender remove "WhatsApp Web"
```

### 4. 🌐 Set Default Browser
Configure which browser to use for web applications:
```bash
depender set-default browser firefox
```

## 💡 Web Application Features

When creating web applications, Depender provides several advanced features:

- **🔖 Automatic Title Detection**: Uses the website's `<title>` tag as the application name
- **🖼️ Smart Icon Detection**: Finds and downloads the website's favicon (with fallbacks)
- **🧪 Browser Profile Detection**: Creates isolated applications using separate browser profiles
- **🏷️ Custom Categories**: Assign applications to specific categories (Network, Utility, etc.)
- **🔄 Session Management**: Web apps maintain their own sessions separate from your main browser

## 🔗 Integration with Desind OS

Depender is designed to work seamlessly with the Desind ecosystem:

### With ArchStart Launcher
```bash
depender list -j | jq -r '.[] | "<item label=\"\(.name)\" icon=\"\(.icon)\"><action name=\"Execute\"><command>depender run \"\(.name)\"</command></action></item>"' > archstart-menu.xml
```

### 🌐 Create Web Applications from Browser
Add this bookmarklet to your browser for one-click web app creation:
```javascript
javascript:(function(){const url=encodeURIComponent(location.href);const name=encodeURIComponent(document.title);window.location.href='depender://create-web?url='+url+'&name='+name;})();
```

### 🧩 System Integration
Web applications created with Depender:
- ✅ Appear in your application menu
- ✅ Have their own window decorations
- ✅ Can be pinned to the taskbar
- ✅ Support notifications
- ✅ Integrate with system search

## ⚙️ Performance Considerations

- **⏱️ Response Time**: All commands respond in under 5ms, adhering to MCX maximum standards
- **🧠 Efficient Parsing**: Only necessary fields from `.desktop` files are parsed
- **💾 Caching**: Results are cached for subsequent queries
- **⚙️ Background Processing**: Long operations (like web scraping) are handled efficiently
- **🔋 Resource Friendly**: Uses minimal system resources even during intensive operations

## 🛠️ Troubleshooting

### 🌐 Web Application Not Working
If a web application doesn't launch properly:
1. Check if your default browser is set correctly: `depender set-default browser firefox`
2. Verify the URL is accessible
3. Try creating the application with a specific name: `depender create web -u https://example.com -n "Example"`

### 🔧 Missing Dependencies
If you encounter errors about missing modules:
```bash
pip install beautifulsoup4 requests
```

### 🔄 Application Not Appearing in Menu
If your application doesn't appear in the menu:
1. Run `gtk-update-icon-cache` to refresh the icon cache
2. Log out and back in, or restart the system

## 🌱 Contributing

We welcome contributions! 🙌 Please feel free to submit pull requests or open issues on our GitHub repository.

### How to Contribute:
1. 🍴 Fork the repository
2. 🌿 Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. 💾 Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push to the branch (`git push origin feature/AmazingFeature`)
5. 📥 Open a Pull Request

## 📜 License

Depender is released under the **GPLv3 License**. See the [LICENSE](LICENSE) file for more details.

---

> "The best applications are the ones you don't have to think about installing." — *Depender Philosophy*

---

⭐️ **Star us on GitHub** — It helps! [![GitHub stars](https://img.shields.io/github/stars/MdX07r/depender?style=social)](https://github.com/MdX07r/depender)

## 📬 Contact

For support or questions, please open an issue on GitHub or contact me directly:

- **GitHub**: [@MdX07r](https://github.com/MdX07r)
- **Email**: mydenglobal@gmail.com

---

Made with ❤️ for the Desind OS community. All contributions are welcome!
