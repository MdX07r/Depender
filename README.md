# Depender - Desktop Application Manager and Creator

![Depender Logo](http://www.w3.org/2000/svg)

Depender is a powerful command-line tool designed for the **Desind** ecosystem that enables users to manage desktop applications and convert websites into native desktop applications with ease. It adheres to the MCX maximum standards (response time < 5ms) while providing a seamless user experience.

## ✨ Features

- **Web Application Creation**: Convert any website into a desktop application with automatic metadata extraction
- **Native Application Management**: List, view information, and manage traditional desktop applications
- **Automatic Metadata Extraction**: Smartly extracts titles, descriptions, and icons from websites
- **JSON Output**: Export application lists in JSON format for programmatic use
- **Web Application Support**: Special handling for web applications with URL tracking
- **Lightweight & Fast**: Built for performance with response times under 5ms
- **Seamless Desind Integration**: Works perfectly with Desind's capsule-based UI system

## 📦 Installation

### Manual Installation
```bash
# Download the installation script
wget https://github.com/MdX07r/depender/raw/main/depender-install

# Make it executable
chmod +x depender-install

# Run as root
sudo ./depender-install
```

### AUR (Arch Linux)
```bash
yay -S depender
```
or:
```bash
paru -S depender
```

### Dependencies
- Python 3.8+
- BeautifulSoup4 (`python3 -m pip install --user beautifulsoup4`)
- Requests (`python3 -m pip install --user requests`)

## 🚀 Getting Started

### Basic Usage
```bash
# List all applications
depender list

# List only web applications
depender list -w

# Create a web application from a URL
depender create-webapp https://example.com

# Create a native application entry
depender create-native "My App" "myapp-command"

# View application information
depender info "Example Website"

# Run an application
depender run "Example Website"

# Remove an application
depender remove "Example Website"
```

## 🌐 Web Application Creation

Depender's most powerful feature is converting websites into desktop applications:

### Basic Web Application
```bash
depender create-webapp https://example.com
```

This command:
1. Fetches the website content
2. Extracts title, description, and favicon
3. Creates a .desktop file using `xdg-open`
4. Marks it as a web application with `X-WebApp=true`
5. Stores the original URL in `X-URL`

### Advanced Web Application Options
```bash
# Custom name
depender create-webapp https://example.com -n "My Custom Name"

# Custom categories
depender create-webapp https://example.com -c "Network;WebBrowser;"

# Custom icon URL
depender create-webapp https://example.com -i https://example.com/custom-icon.png

# Create with specific browser
depender create-webapp https://example.com --exec "firefox --private-window %U"
```

## 🖥️ Native Application Management

### Creating Native Applications
```bash
# Basic native application
depender create-native "VS Code" "code"

# With description and icon
depender create-native "VS Code" "code" -d "Code editing. Redefined." -i /usr/share/icons/vscode.png
```

### Managing Applications
```bash
# List applications with search
depender list -s "browser"

# List applications in JSON format
depender list -j

# View detailed application information
depender info "Google Chrome"

# Remove an application
depender remove "Google Chrome"
```

## ⚙️ Integration with Desind OS

Depender works seamlessly with Desind's unique capsule-based UI:

```bash
# Create a web app for Desind documentation
depender create-webapp https://docs.desind.example -n "Desind Docs"

# The new application will automatically appear in ArchStart launcher
```

### Capsule Integration
- Web applications appear as capsules in the Desind interface
- Automatic categorization based on website content
- Supports Desind's dynamic color engine (Pywal integration)
- Works with Desind's RTL/LTR language support

## 🔍 Advanced Usage

### Batch Operations
```bash
# Create multiple web applications from a list
cat websites.txt | while read url; do
  depender create-webapp "$url"
done

# Export all web applications to JSON
depender list -w -j > webapps.json
```

### Programmatic Use
```bash
# Get application path for scripting
APP_PATH=$(depender info "Example" | grep "File Path" | cut -d ':' -f 2 | tr -d ' ')
xdg-open "$APP_PATH"
```

### Custom Browser Profiles
```bash
# Create web app with custom browser profile
depender create-webapp https://gmail.com -n "Gmail" \
  --exec "firefox -P 'Work' --class Gmail --no-remote %U"
```

## 🛠️ Troubleshooting

### Common Issues

**Website Metadata Not Extracted Properly**
```bash
# Manually specify name and icon
depender create-webapp https://problem-site.com -n "Custom Name" -i https://problem-site.com/custom-icon.png
```

**Application Not Appearing in Launcher**
```bash
# Update desktop database
update-desktop-database ~/.local/share/applications
```

**Missing Dependencies**
```bash
# Install required Python packages
python3 -m pip install --user beautifulsoup4 requests
```

### Debug Mode
```bash
# Run with debug output
DEP_DEBUG=1 depender create-webapp https://example.com
```

## 🤝 Contributing

We welcome contributions to Depender! Here's how you can help:

1. **Report bugs** by opening an issue on GitHub
2. **Request features** by creating a feature request issue
3. **Submit pull requests** for bug fixes or new features
4. **Improve documentation** by updating the README or adding examples

### Development Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/depender.git
cd depender

# Install development dependencies
python3 -m pip install --user -r requirements-dev.txt

# Run tests
pytest
```

## 📜 License

Depender is released under the **GNU General Public License v3.0**.

```
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

## 📬 Support

For support and inquiries, please contact us:

- **Email**: mydenglobal@gmail.com
