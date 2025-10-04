#!/bin/bash

# Install Depender
echo "Installing Depender - Desktop File Management Tool for Desind"

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
from pathlib import Path

class Depender:
    def __init__(self):
        self.app_dirs = [
            "/usr/share/applications",
            str(Path.home() / ".local/share/applications")
        ]
        self.apps = []
        self.load_apps()
    
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
                'file_path': file_path
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
    
    def list_apps(self, category=None, search_query=None):
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
        
        # Return results
        results = []
        for app in filtered_apps:
            results.append({
                'name': app['name'],
                'comment': app['comment'],
                'icon': app['icon'],
                'exec': app['exec']
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
                    'file_path': app['file_path']
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

def main():
    parser = argparse.ArgumentParser(description='Depender - .desktop File Management Tool for Daruza')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # list command
    list_parser = subparsers.add_parser('list', help='List all applications')
    list_parser.add_argument('-c', '--category', help='Filter by category')
    list_parser.add_argument('-s', '--search', help='Search applications')
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
    
    args = parser.parse_args()
    
    depender = Depender()
    
    if args.command == 'list':
        apps = depender.list_apps(category=args.category, search_query=args.search)
        
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
Comment=Desktop File Management Tool for Daruza
Exec=depender
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;Development;
EOF

# Create documentation directory
mkdir -p "${DEPENDER_DOC_DIR}"

# Documentation file
cat > "${DEPENDER_README}" << 'EOF'
# Depender - Desktop File Management Tool for Daruza

Depender is a lightweight and powerful command-line tool designed specifically for the **Daruza** operating system. It allows users to manage `.desktop` files efficiently and launch applications seamlessly.

## Features

- **Lightweight and Fast**: Built with performance in mind, Depender adheres to MCX standards (response time < 5ms).
- **List Applications**: View all installed applications with filtering and search capabilities.
- **Application Details**: Get detailed information about any application, including its name, description, icon, and execution command.
- **Launch Applications**: Easily launch applications directly from the command line.
- **JSON Output**: Export application lists in JSON format for easy integration with other tools.
- **Integration with Desind**: Designed to work seamlessly with the Daruza ecosystem, including ArchStart and other system components.
EOF

echo "Installation Done! run "depender" command for the list."
