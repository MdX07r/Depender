Below is the `README.md` file in English, explaining that the tool is in beta and currently supports only the Arabic language:

---

# Depender - A `.desktop` File Management Tool for Daruza

Depender is a lightweight and powerful command-line tool designed specifically for the **Daruza** Desktop Environment. It allows users to manage `.desktop` files efficiently and launch applications seamlessly.

---

## Features

- **Lightweight and Fast**: Built with performance in mind, Depender adheres to MCX standards (response time < 5ms).
- **List Applications**: View all installed applications with filtering and search capabilities.
- **Application Details**: Get detailed information about any application, including its name, description, icon, and execution command.
- **Launch Applications**: Easily launch applications directly from the command line.
- **JSON Output**: Export application lists in JSON format for easy integration with other tools.
- **Integration with Daruza**: Designed to work seamlessly with the Daruza ecosystem, including ArchStart and other system components.

---

## Usage

### 1. List Applications
Display all installed applications:
```bash
depender list
```

Filter by category:
```bash
depender list -c Utility
```

Search for applications:
```bash
depender list -s "file"
```

Output in JSON format:
```bash
depender list -j
```

### 2. View Application Information
Get detailed information about a specific application:
```bash
depender info "Drile - File Manager"
```

### 3. Launch an Application
Run a specific application:
```bash
depender run "Drile - File Manager"
```

### 4. Search for Applications
Search for applications based on a query:
```bash
depender search "file"
```

---

## Installation

### Manual Installation
You can install Depender manually by running the installation script:
```bash
sudo ./depender-install
```

### Arch Linux (AUR)
Depender is available on the Arch User Repository (AUR). You can install it using an AUR helper like `yay` or `paru`:
```bash
yay -S depender
```

---

## Beta Status

**Depender is currently in beta.** While it is functional and stable for basic use cases, it is still under active development. Please report any issues or bugs you encounter.

---

## Language Support

At this stage, **Depender supports only the Arabic language**. Future updates may include support for additional languages.

---

## Contributing

We welcome contributions from the community! If you'd like to help improve Depender, please feel free to submit pull requests or open issues on our GitHub repository.

---

## License

Depender is released under the **GPLv3 License**. See the (LICENSE) file for more details.

---

For further assistance or feedback, please contact us at:  
**Email**: mydenglobal@gmail.com 
**GitHub Repository**: [https://github.com/MdX07r/]epender](https://github.com/MdX07r/depender)

--- 

This `README.md` file provides a clear overview of the tool, its features, and its current limitations while emphasizing its beta status and exclusive Arabic language support.
