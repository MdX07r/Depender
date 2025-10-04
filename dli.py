#!/usr/bin/env python3
import os
import sys
import argparse
import configparser
import glob
import json
import subprocess
from bs4 import BeautifulSoup
from pathlib import Path
from urllib.parse import urlparse
import re
import mimetypes
import tempfile
import shutil
import time

class Depender:
    def __init__(self):
        self.app_dirs = [
            "/usr/share/applications",
            str(Path.home() / ".local/share/applications")
        ]
        self.apps = []
        self.load_apps()
        self.temp_dir = tempfile.mkdtemp()
    
    def __del__(self):
        """Clean up temporary directory when object is destroyed"""
        try:
            if os.path.exists(self.temp_dir):
                shutil.rmtree(self.temp_dir)
        except Exception as e:
            print(f"Warning: Failed to clean up temporary directory: {str(e)}", file=sys.stderr)
    
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
                'is_webapp': 'X-WebApp' in entry
            }
            
            # Handle variables in Execute field
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
    
    def list_apps(self, category=None, search_query=None, is_webapp=None):
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
        
        # Filter by webapp
        if is_webapp is not None:
            filtered_apps = [app for app in filtered_apps if app['is_webapp'] == is_webapp]
        
        return filtered_apps
    
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
                    'is_webapp': app['is_webapp']
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
    
    def create_webapp(self, url, name=None, categories=None, icon_url=None):
        """Create a web application from a URL"""
        try:
            # Validate URL
            parsed_url = urlparse(url)
            if not parsed_url.scheme or not parsed_url.netloc:
                raise ValueError("Invalid URL format. Please provide a complete URL (e.g., https://example.com)")
            
            # Fetch website content
            headers = {
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # Parse HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract title if not provided
            if not name:
                title_tag = soup.title
                name = title_tag.string.strip() if title_tag and title_tag.string else parsed_url.netloc
            
            # Extract description
            description = ""
            meta_desc = soup.find('meta', attrs={'name': 'description'})
            if meta_desc and meta_desc.get('content'):
                description = meta_desc['content'].strip()
            
            # Extract icon if not provided
            icon_path = ""
            if icon_url:
                icon_path = self.download_icon(icon_url)
            else:
                # Try to find favicon
                favicon = None
                # Look for link with rel="icon" or rel="shortcut icon"
                for rel_value in ['icon', 'shortcut icon', 'apple-touch-icon']:
                    favicon = soup.find('link', rel=rel_value)
                    if favicon:
                        break
                
                if favicon and favicon.get('href'):
                    icon_url = favicon['href']
                    # Make absolute URL if necessary
                    if not urlparse(icon_url).netloc:
                        icon_url = f"{parsed_url.scheme}://{parsed_url.netloc}{icon_url}"
                    icon_path = self.download_icon(icon_url)
            
            # If no icon found, use default
            if not icon_path:
                icon_path = "applications-internet"
            
            # Determine categories
            if not categories:
                # Default categories for web apps
                categories = ["Network;WebBrowser;"]
            elif not categories.endswith(';'):
                categories += ';'
            
            # Create desktop file content
            desktop_content = f"""[Desktop Entry]
Name={name}
Comment={description}
Exec=xdg-open {url}
Icon={icon_path}
Terminal=false
Type=Application
Categories={categories}
X-WebApp=true
X-URL={url}
"""
            
            # Save desktop file
            desktop_filename = f"webapp-{re.sub(r'[^a-zA-Z0-9]', '_', name.lower())}.desktop"
            desktop_path = os.path.join(Path.home() / ".local/share/applications", desktop_filename)
            
            with open(desktop_path, 'w', encoding='utf-8') as f:
                f.write(desktop_content)
            
            # Reload applications
            self.load_apps()
            
            print(f"Web application created successfully: {desktop_path}")
            return {
                'name': name,
                'path': desktop_path,
                'url': url
            }
            
        except Exception as e:
            print(f"Failed to create web application: {str(e)}", file=sys.stderr)
            return None
    
    def download_icon(self, icon_url):
        """Download an icon from a URL and save it locally"""
        try:
            response = requests.get(icon_url, timeout=5)
            response.raise_for_status()
            
            # Determine file extension from content type
            content_type = response.headers.get('Content-Type', '')
            ext = mimetypes.guess_extension(content_type.split(';')[0]) or '.png'
            
            # Create a temporary file
            icon_path = os.path.join(self.temp_dir, f"icon{ext}")
            
            with open(icon_path, 'wb') as f:
                f.write(response.content)
            
            return icon_path
        except Exception as e:
            print(f"Warning: Failed to download icon: {str(e)}", file=sys.stderr)
            return ""
    
    def create_native_app(self, app_name, exec_command, categories=None, icon_path=None, comment=""):
        """Create a native application entry"""
        try:
            # Determine categories
            if not categories:
                categories = "Utility;"
            elif not categories.endswith(';'):
                categories += ';'
            
            # Create desktop file content
            desktop_content = f"""[Desktop Entry]
Name={app_name}
Comment={comment}
Exec={exec_command}
"""
            if icon_path:
                desktop_content += f"Icon={icon_path}\n"
                
            desktop_content += f"""Terminal=false
Type=Application
Categories={categories}
"""
            
            # Save desktop file
            desktop_filename = f"{re.sub(r'[^a-zA-Z0-9]', '_', app_name.lower())}.desktop"
            desktop_path = os.path.join(Path.home() / ".local/share/applications", desktop_filename)
            
            with open(desktop_path, 'w', encoding='utf-8') as f:
                f.write(desktop_content)
            
            # Reload applications
            self.load_apps()
            
            print(f"Native application created successfully: {desktop_path}")
            return {
                'name': app_name,
                'path': desktop_path
            }
            
        except Exception as e:
            print(f"Failed to create native application: {str(e)}", file=sys.stderr)
            return None
    
    def remove_app(self, app_name):
        """Remove an application by name"""
        for app in self.apps:
            if app['name'].lower() == app_name.lower():
                try:
                    os.remove(app['file_path'])
                    self.load_apps()
                    print(f"Application '{app_name}' removed successfully")
                    return True
                except Exception as e:
                    print(f"Failed to remove application: {str(e)}", file=sys.stderr)
                    return False
        print(f"Application '{app_name}' not found")
        return False

def main():
    parser = argparse.ArgumentParser(description='Depender - Desktop Application Manager and Creator')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # list command
    list_parser = subparsers.add_parser('list', help='List all applications')
    list_parser.add_argument('-c', '--category', help='Filter by category')
    list_parser.add_argument('-s', '--search', help='Search applications')
    list_parser.add_argument('-w', '--webapps', action='store_true', help='Show only web applications')
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
    
    # create-webapp command
    create_webapp_parser = subparsers.add_parser('create-webapp', help='Create a web application from a URL')
    create_webapp_parser.add_argument('url', help='Website URL')
    create_webapp_parser.add_argument('-n', '--name', help='Application name (optional)')
    create_webapp_parser.add_argument('-c', '--categories', help='Application categories (optional, default: Network;WebBrowser;)')
    create_webapp_parser.add_argument('-i', '--icon', help='Custom icon URL (optional)')
    
    # create-native command
    create_native_parser = subparsers.add_parser('create-native', help='Create a native application entry')
    create_native_parser.add_argument('name', help='Application name')
    create_native_parser.add_argument('exec', help='Execution command')
    create_native_parser.add_argument('-c', '--categories', help='Application categories (optional, default: Utility;)')
    create_native_parser.add_argument('-i', '--icon', help='Icon path or name (optional)')
    create_native_parser.add_argument('-d', '--description', help='Application description (optional)')
    
    # remove command
    remove_parser = subparsers.add_parser('remove', help='Remove an application')
    remove_parser.add_argument('app_name', help='Application name to remove')
    
    args = parser.parse_args()
    
    depender = Depender()
    
    if args.command == 'list':
        is_webapp = args.webapps if args.webapps else None
        apps = depender.list_apps(category=args.category, search_query=args.search, is_webapp=is_webapp)
        
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
        if app_info['is_webapp']:
            print("Type: Web Application")
        else:
            print("Type: Native Application")
    
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
    
    elif args.command == 'create-webapp':
        result = depender.create_webapp(
            url=args.url,
            name=args.name,
            categories=args.categories,
            icon_url=args.icon
        )
        if not result:
            sys.exit(1)
    
    elif args.command == 'create-native':
        result = depender.create_native_app(
            app_name=args.name,
            exec_command=args.exec,
            categories=args.categories,
            icon_path=args.icon,
            comment=args.description
        )
        if not result:
            sys.exit(1)
    
    elif args.command == 'remove':
        if not depender.remove_app(args.app_name):
            sys.exit(1)
    
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()s


