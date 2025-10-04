#!/bin/bash

# Install Depender
echo "Installing Depender - Advanced Application Manager"

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo "Please run this script with root privileges"
    exit 1
fi

# File paths
DEPENDER_BIN="/usr/bin/depender"
DEPENDER_DESKTOP="/usr/share/applications/depender.desktop"
DEPENDER_DOC_DIR="/usr/share/doc/depender"
DEPENDER_README="${DEPENDER_DOC_DIR}/README.md"

# Create files
echo "Creating Depender files..."

# Depender tool
cat > "${DEPENDER_BIN}" << 'EOF'
#!/usr/bin/env python3
import os
import sys
import argparse
import configparser
import glob
import json
import subprocess
import re
import urllib.request
import urllib.error
from html.parser import HTMLParser
from pathlib import Path
import ssl

class Depender:
    def __init__(self):
        self.app_dirs = [
            "/usr/share/applications",
            str(Path.home() / ".local/share/applications")
        ]
        self.apps = []
        self.load_apps()
        self.browser_profiles = self.detect_browser_profiles()
    
    def load_apps(self):
        """Load all .desktop files from specified directories"""
        self.apps = []
        for app_dir in self.app_dirs:
            if not os.path.exists(app_dir):
                continue
                
            for desktop_file in glob.glob(os.path.join(app_dir, "*.desktop")):
                try:
                    app = self.parse_desktop_file(desktop_file)
                    if app:
                        self.apps.append(app)
                except Exception as e:
                    print(f"Warning: Failed to load {desktop_file}: {str(e)}", file=sys.stderr)
    
    def parse_desktop_file(self, file_path):
        """Parse .desktop file and extract important information"""
        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str  # Preserve case sensitivity
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                config.read_file(f)
            
            if 'Desktop Entry' not in config:
                return None
                
            entry = config['Desktop Entry']
            
            # Check if this is an executable application
            if entry.get('Type', '') != 'Application':
                return None
                
            # Check if the application has NoDisplay=true
            if entry.getboolean('NoDisplay', False):
                return None
                
            # Gather basic information
            app = {
                'name': entry.get('Name', ''),
                'comment': entry.get('Comment', ''),
                'exec': entry.get('Exec', ''),
                'icon': entry.get('Icon', ''),
                'categories': entry.get('Categories', '').split(';') if entry.get('Categories') else [],
                'file_path': file_path,
                'is_web_app': entry.get('X-WebApp', 'false').lower() == 'true',
                'url': entry.get('X-WebApp-URL', '')
            }
            
            # Handle variables in Exec field
            if app['exec']:
                app['exec'] = self.expand_exec_command(app['exec'])
                
            return app
        except Exception as e:
            print(f"Error parsing {file_path}: {str(e)}", file=sys.stderr)
            return None
    
    def expand_exec_command(self, command):
        """Expand Exec commands by replacing variables like %U, %F, etc."""
        # Replace common variables
        replacements = {
            '%U': '',
            '%F': '',
            '%u': '',
            '%f': '',
            '%i': '',
            '%c': '',
            '%k': '',
            '%v': '',
            '%m': '',
            '%M': '',
            '%n': '',
            '%N': '',
            '%D': '',
            '%d': '',
            '%w': '',
            '%W': '',
            '%S': '',
            '%s': '',
            '%t': '',
            '%T': '',
            '%p': '',
            '%P': '',
            '%z': '',
            '%Z': '',
            '%e': '',
            '%E': '',
            '%o': '',
            '%O': '',
            '%q': '',
            '%Q': '',
            '%x': '',
            '%X': '',
            '%y': '',
            '%Y': '',
            '%l': '',
            '%L': '',
            '%h': '',
            '%H': '',
            '%a': '',
            '%A': '',
            '%b': '',
            '%B': '',
            '%g': '',
            '%G': '',
            '%j': '',
            '%J': '',
            '%r': '',
            '%R': '',
            '%v': '',
            '%V': '',
            '%w': '',
            '%W': '',
            '%z': '',
            '%Z': ''
        }
        
        for key, value in replacements.items():
            command = command.replace(key, value)
            
        return command
    
    def list_apps(self, category=None, search_query=None, web_only=False):
        """List applications with filtering options"""
        filtered_apps = self.apps.copy()
        
        # Filter by category
        if category:
            filtered_apps = [app for app in filtered_apps if category in app['categories']]
        
        # Filter by search query
        if search_query:
            search_query = search_query.lower()
            filtered_apps = [
                app for app in filtered_apps
                if search_query in app['name'].lower() or 
                   (app['comment'] and search_query in app['comment'].lower())
            ]
        
        # Filter web apps
        if web_only:
            filtered_apps = [app for app in filtered_apps if app.get('is_web_app', False)]
        
        # Return results
        results = []
        for app in filtered_apps:
            results.append({
                'name': app['name'],
                'comment': app['comment'],
                'icon': app['icon'],
                'exec': app['exec'],
                'is_web_app': app.get('is_web_app', False),
                'url': app.get('url', '')
            })
        
        return results
    
    def get_app_info(self, app_name):
        """Get detailed information about an application"""
        for app in self.apps:
            if app['name'].lower() == app_name.lower():
                return {
                    'name': app['name'],
                    'comment': app['comment'],
                    'exec': app['exec'],
                    'icon': app['icon'],
                    'categories': app['categories'],
                    'file_path': app['file_path'],
                    'is_web_app': app.get('is_web_app', False),
                    'url': app.get('url', '')
                }
        return None
    
    def run_app(self, app_name):
        """Run a specific application"""
        for app in self.apps:
            if app['name'].lower() == app_name.lower() and app['exec']:
                try:
                    # Split command into parts
                    command_parts = self.split_exec_command(app['exec'])
                    
                    # Run the command
                    subprocess.Popen(command_parts)
                    return True
                except Exception as e:
                    print(f"Failed to run application: {str(e)}", file=sys.stderr)
                    return False
        return False
    
    def split_exec_command(self, command):
        """Split Exec command into parts while handling quotes"""
        parts = []
        current = []
        in_quote = None
        escape = False
        
        for char in command:
            if escape:
                current.append(char)
                escape = False
            elif char == '\\':
                escape = True
            elif in_quote:
                if char == in_quote:
                    in_quote = None
                else:
                    current.append(char)
            elif char in ('"', "'"):
                in_quote = char
            elif char.isspace():
                if current:
                    parts.append(''.join(current))
                    current = []
            else:
                current.append(char)
        
        if current:
            parts.append(''.join(current))
            
        return parts
    
    def search_apps(self, query):
        """Search for applications based on a query"""
        return self.list_apps(search_query=query)
    
    def detect_browser_profiles(self):
        """Detect available browser profiles for web apps"""
        profiles = []
        
        # Check Firefox profiles
        firefox_path = Path.home() / ".mozilla/firefox"
        if firefox_path.exists():
            for profile in firefox_path.glob("*.default*"):
                profiles.append({
                    'name': 'Firefox',
                    'profile': profile.name,
                    'path': str(profile),
                    'command': 'firefox --profile "{}"'
                })
        
        # Check Chrome profiles
        chrome_path = Path.home() / ".config/google-chrome"
        if chrome_path.exists():
            for profile in chrome_path.glob("Profile *"):
                profiles.append({
                    'name': 'Chrome',
                    'profile': profile.name,
                    'path': str(profile),
                    'command': 'google-chrome --profile-directory="{}"'
                })
        
        # Check Chromium profiles
        chromium_path = Path.home() / ".config/chromium"
        if chromium_path.exists():
            for profile in chromium_path.glob("Profile *"):
                profiles.append({
                    'name': 'Chromium',
                    'profile': profile.name,
                    'path': str(profile),
                    'command': 'chromium --profile-directory="{}"'
                })
        
        return profiles
    
    def create_web_app(self, url, name=None, icon=None, category="Network"):
        """Create a web application from a URL"""
        try:
            # Validate URL
            if not url.startswith(('http://', 'https://')):
                url = 'https://' + url
            
            # Create a context that ignores SSL verification for problematic sites
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            
            # Get website information if name/icon not provided
            if not name or not icon:
                try:
                    # Fetch website content using urllib
                    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                    with urllib.request.urlopen(req, context=ctx, timeout=10) as response:
                        html_content = response.read().decode('utf-8', errors='ignore')
                    
                    # Parse HTML to extract title and favicon
                    parser = SimpleHTMLParser()
                    parser.feed(html_content)
                    
                    # Get title as name if not provided
                    if not name:
                        name = parser.title.strip() if parser.title else url.split('//')[1].split('/')[0]
                    
                    # Get icon if not provided
                    if not icon and parser.favicon:
                        favicon = parser.favicon
                        # Handle relative URLs
                        if favicon.startswith('//'):
                            favicon = 'https:' + favicon
                        elif favicon.startswith('/'):
                            favicon = url.split('://')[0] + '://' + url.split('://')[1].split('/')[0] + favicon
                        elif not favicon.startswith(('http://', 'https://')):
                            favicon = url.rstrip('/') + '/' + favicon
                        
                        try:
                            # Download the icon
                            req = urllib.request.Request(favicon, headers={'User-Agent': 'Mozilla/5.0'})
                            with urllib.request.urlopen(req, context=ctx, timeout=5) as response:
                                icon_data = response.read()
                            
                            icon_path = Path.home() / f".local/share/icons/{name.lower().replace(' ', '-')}.png"
                            icon_path.parent.mkdir(parents=True, exist_ok=True)
                            
                            with open(icon_path, 'wb') as f:
                                f.write(icon_data)
                            
                            icon = str(icon_path)
                        except:
                            icon = 'web-browser'
                    else:
                        icon = 'web-browser'
                except Exception as e:
                    print(f"Warning: Failed to fetch website data: {str(e)}", file=sys.stderr)
                    if not name:
                        name = url
                    icon = 'web-browser'
            
            # Generate a safe filename
            filename = f"{name.lower().replace(' ', '-')}.desktop"
            desktop_file = Path.home() / f".local/share/applications/{filename}"
            
            # Create the desktop file
            with open(desktop_file, 'w') as f:
                f.write("[Desktop Entry]\n")
                f.write(f"Name={name}\n")
                f.write(f"Comment=Web application for {url}\n")
                f.write(f"Exec={self.get_browser_command(url)}\n")
                f.write(f"Icon={icon}\n")
                f.write("Terminal=false\n")
                f.write("Type=Application\n")
                f.write(f"Categories={category};\n")
                f.write("StartupWMClass=web-app\n")
                f.write(f"X-WebApp=true\n")
                f.write(f"X-WebApp-URL={url}\n")
            
            # Reload applications
            self.load_apps()
            return True, f"Web application '{name}' created successfully at {desktop_file}"
            
        except Exception as e:
            return False, f"Failed to create web application: {str(e)}"
    
    def get_browser_command(self, url):
        """Get the appropriate browser command based on available browsers"""
        # Check for preferred browser in config
        config_path = Path.home() / ".config/depender/config"
        if config_path.exists():
            with open(config_path, 'r') as f:
                for line in f:
                    if line.startswith('browser='):
                        browser = line.split('=')[1].strip()
                        if browser == 'firefox':
                            return f"firefox '{url}'"
                        elif browser == 'chrome':
                            return f"google-chrome '{url}'"
                        elif browser == 'chromium':
                            return f"chromium '{url}'"
        
        # Detect available browsers
        browsers = [
            ('firefox', 'firefox'),
            ('google-chrome', 'google-chrome'),
            ('chromium', 'chromium')
        ]
        
        for cmd, browser in browsers:
            if self.is_command_available(cmd):
                if browser == 'firefox':
                    return f"firefox '{url}'"
                elif browser == 'chrome':
                    return f"google-chrome '{url}'"
                elif browser == 'chromium':
                    return f"chromium '{url}'"
        
        # Default to xdg-open if no browser found
        return f"xdg-open '{url}'"
    
    def is_command_available(self, command):
        """Check if a command is available in PATH"""
        try:
            subprocess.run(['which', command], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return True
        except subprocess.CalledProcessError:
            return False
    
    def create_application(self, name, exec_cmd, icon=None, comment=None, category="Utility"):
        """Create a new application .desktop file"""
        try:
            # Generate a safe filename
            filename = f"{name.lower().replace(' ', '-')}.desktop"
            desktop_file = Path.home() / f".local/share/applications/{filename}"
            
            # Create the desktop file
            with open(desktop_file, 'w') as f:
                f.write("[Desktop Entry]\n")
                f.write(f"Name={name}\n")
                if comment:
                    f.write(f"Comment={comment}\n")
                f.write(f"Exec={exec_cmd}\n")
                if icon:
                    f.write(f"Icon={icon}\n")
                else:
                    f.write("Icon=application-x-executable\n")
                f.write("Terminal=false\n")
                f.write("Type=Application\n")
                f.write(f"Categories={category};\n")
            
            # Reload applications
            self.load_apps()
            return True, f"Application '{name}' created successfully at {desktop_file}"
            
        except Exception as e:
            return False, f"Failed to create application: {str(e)}"
    
    def remove_app(self, app_name):
        """Remove an application by name"""
        for app in self.apps:
            if app['name'].lower() == app_name.lower():
                try:
                    os.remove(app['file_path'])
                    self.load_apps()
                    return True, f"Application '{app_name}' removed successfully"
                except Exception as e:
                    return False, f"Failed to remove application: {str(e)}"
        
        return False, f"Application '{app_name}' not found"
    
    def set_default_browser(self, browser):
        """Set the default browser for web applications"""
        config_dir = Path.home() / ".config/depender"
        config_dir.mkdir(parents=True, exist_ok=True)
        
        config_path = config_dir / "config"
        
        with open(config_path, 'w') as f:
            f.write(f"browser={browser}\n")
        
        return True, f"Default browser set to {browser}"

class SimpleHTMLParser(HTMLParser):
    """Custom HTML parser to extract title and favicon without external dependencies"""
    def __init__(self):
        super().__init__()
        self.title = ""
        self.favicon = None
        self.in_title = False
        self.in_head = False
    
    def handle_starttag(self, tag, attrs):
        # Track if we're in the head section
        if tag == "head":
            self.in_head = True
        
        # Extract title
        if tag == "title" and self.in_head:
            self.in_title = True
        
        # Extract favicon
        if self.in_head and tag == "link":
            attrs_dict = dict(attrs)
            rel = attrs_dict.get("rel", "").lower()
            
            # Check for common favicon patterns
            if "icon" in rel or "shortcut icon" in rel:
                self.favicon = attrs_dict.get("href")
    
    def handle_data(self, data):
        if self.in_title:
            self.title += data
    
    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False
        if tag == "head":
            self.in_head = False

def main():
    parser = argparse.ArgumentParser(description='Depender - Advanced Application Manager for Desind OS')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # list command
    list_parser = subparsers.add_parser('list', help='List all applications')
    list_parser.add_argument('-c', '--category', help='Filter by category')
    list_parser.add_argument('-s', '--search', help='Search applications')
    list_parser.add_argument('-w', '--web', action='store_true', help='List only web applications')
    list_parser.add_argument('-j', '--json', action='store_true', help='Output in JSON format')
    
    # info command
    info_parser = subparsers.add_parser('info', help='Display application information')
    info_parser.add_argument('app_name', help='Application name')
    
    # run command
    run_parser = subparsers.add_parser('run', help='Run an application')
    run_parser.add_argument('app_name', help='Application name')
    
    # search command
    search_parser = subparsers.add_parser('search', help='Search applications')
    search_parser.add_argument('query', help='Search query')
    search_parser.add_argument('-j', '--json', action='store_true', help='Output in JSON format')
    
    # create command
    create_parser = subparsers.add_parser('create', help='Create a new application')
    create_subparsers = create_parser.add_subparsers(dest='create_type', help='Type of application to create')
    
    # create app command
    app_parser = create_subparsers.add_parser('app', help='Create a regular application')
    app_parser.add_argument('-n', '--name', required=True, help='Application name')
    app_parser.add_argument('-e', '--exec', required=True, help='Execution command')
    app_parser.add_argument('-i', '--icon', help='Icon path or name')
    app_parser.add_argument('-c', '--comment', help='Application description')
    app_parser.add_argument('-g', '--category', default='Utility', help='Application category')
    
    # create web command
    web_parser = create_subparsers.add_parser('web', help='Create a web application from a URL')
    web_parser.add_argument('-u', '--url', required=True, help='Website URL')
    web_parser.add_argument('-n', '--name', help='Application name (optional)')
    web_parser.add_argument('-i', '--icon', help='Icon path or name (optional)')
    web_parser.add_argument('-g', '--category', default='Network', help='Application category')
    
    # remove command
    remove_parser = subparsers.add_parser('remove', help='Remove an application')
    remove_parser.add_argument('app_name', help='Application name to remove')
    
    # set-default command
    set_default_parser = subparsers.add_parser('set-default', help='Set default settings')
    set_default_subparsers = set_default_parser.add_subparsers(dest='setting', help='Setting to configure')
    
    # set-default browser command
    browser_parser = set_default_subparsers.add_parser('browser', help='Set default browser')
    browser_parser.add_argument('browser', choices=['firefox', 'chrome', 'chromium'], help='Browser to use')
    
    args = parser.parse_args()
    
    depender = Depender()
    
    if args.command == 'list':
        apps = depender.list_apps(category=args.category, search_query=args.search, web_only=args.web)
        
        if args.json:
            print(json.dumps(apps, indent=2, ensure_ascii=False))
        else:
            if not apps:
                print("No matching applications found.")
                return
            
            print(f"{'Name':<30} {'Description':<40}")
            print("-" * 70)
            for app in apps:
                name = app['name'][:27] + "..." if len(app['name']) > 30 else app['name']
                comment = app['comment'][:37] + "..." if app['comment'] and len(app['comment']) > 40 else (app['comment'] or "")
                print(f"{name:<30} {comment:<40}")
    
    elif args.command == 'info':
        app_info = depender.get_app_info(args.app_name)
        if not app_info:
            print(f"Application '{args.app_name}' not found.")
            sys.exit(1)
        
        print(f"Name: {app_info['name']}")
        if app_info['comment']:
            print(f"Description: {app_info['comment']}")
        print(f"Command: {app_info['exec']}")
        print(f"Icon: {app_info['icon']}")
        print(f"Categories: {', '.join(app_info['categories'])}")
        print(f"File Path: {app_info['file_path']}")
        if app_info.get('is_web_app', False):
            print(f"Web Application: Yes")
            print(f"URL: {app_info.get('url', '')}")
    
    elif args.command == 'run':
        if not depender.run_app(args.app_name):
            print(f"Failed to run application '{args.app_name}'.")
            sys.exit(1)
    
    elif args.command == 'search':
        apps = depender.search_apps(args.query)
        
        if args.json:
            print(json.dumps(apps, indent=2, ensure_ascii=False))
        else:
            if not apps:
                print(f"No matching applications found for '{args.query}'.")
                return
            
            print(f"{'Name':<30} {'Description':<40}")
            print("-" * 70)
            for app in apps:
                name = app['name'][:27] + "..." if len(app['name']) > 30 else app['name']
                comment = app['comment'][:37] + "..." if app['comment'] and len(app['comment']) > 40 else (app['comment'] or "")
                print(f"{name:<30} {comment:<40}")
    
    elif args.command == 'create':
        if args.create_type == 'app':
            success, message = depender.create_application(
                args.name,
                args.exec,
                args.icon,
                args.comment,
                args.category
            )
            if success:
                print(message)
            else:
                print(f"Error: {message}")
                sys.exit(1)
        
        elif args.create_type == 'web':
            success, message = depender.create_web_app(
                args.url,
                args.name,
                args.icon,
                args.category
            )
            if success:
                print(message)
            else:
                print(f"Error: {message}")
                sys.exit(1)
    
    elif args.command == 'remove':
        success, message = depender.remove_app(args.app_name)
        if success:
            print(message)
        else:
            print(f"Error: {message}")
            sys.exit(1)
    
    elif args.command == 'set-default':
        if args.setting == 'browser':
            success, message = depender.set_default_browser(args.browser)
            if success:
                print(message)
            else:
                print(f"Error: {message}")
                sys.exit(1)
    
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Desktop entry file
cat > "${DEPENDER_DESKTOP}" << 'EOF'
[Desktop Entry]
Name=Depender
Comment=Advanced Application Manager
Exec=depender
Icon=system-software-install
Terminal=true
Type=Application
Categories=Utility;Development;System;
EOF

echo "Done! Run "depender" Command To Show Commands List."
