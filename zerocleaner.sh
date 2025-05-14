#!/bin/bash

# ZeroCleaner - Professional Arch Linux Cleaning Script
# Author: Claude
# Date: May 14, 2025
# Description: This script thoroughly cleans Arch Linux systems by removing orphaned packages,
#              cache files, temporary files, and other unnecessary data

# ANSI Color codes for modern aesthetic
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if script is running with root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${BOLD}ERROR:${NC} This script must be run as root"
        echo -e "${YELLOW}Please use: sudo $0${NC}"
        exit 1
    fi
}

# Display modern banner and logo
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "███████╗███████╗██████╗  ██████╗  ██████╗██╗     ███████╗ █████╗ ███╗   ██╗███████╗██████╗ "
    echo "╚══███╔╝██╔════╝██╔══██╗██╔═══██╗██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██╔════╝██╔══██╗"
    echo "  ███╔╝ █████╗  ██████╔╝██║   ██║██║     ██║     █████╗  ███████║██╔██╗ ██║█████╗  ██████╔╝"
    echo " ███╔╝  ██╔══╝  ██╔══██╗██║   ██║██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██╔══╝  ██╔══██╗"
    echo "███████╗███████╗██║  ██║╚██████╔╝╚██████╗███████╗███████╗██║  ██║██║ ╚████║███████╗██║  ██║"
    echo "╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${MAGENTA}${BOLD}================== Professional Arch Linux System Cleaner ==================${NC}"
    echo -e "${BLUE}                           Version 1.0.0                              ${NC}"
    echo ""
}

# Display loading animation
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    echo -n "  "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\b\b${YELLOW}[%c]${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\b\b\b\b"
    echo -e "${GREEN}[✓]${NC}"
}

# Display system information before cleaning
print_system_info() {
    echo -e "${MAGENTA}${BOLD}❯ SYSTEM INFORMATION${NC}"
    echo -e "${BLUE}├─ Disk usage:${NC}"
    df -h / | grep -v "Filesystem" | awk '{print "│  └─ " $5 " used of " $2 " total (" $4 " available)"}'
    
    local total_packages=$(pacman -Q | wc -l)
    local orphaned_packages=$(pacman -Qtdq 2>/dev/null | wc -l || echo 0)
    local pacman_cache_size=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1)
    
    echo -e "${BLUE}├─ Packages:${NC}"
    echo -e "│  ├─ Total installed: ${YELLOW}${total_packages}${NC}"
    echo -e "│  └─ Orphaned: ${YELLOW}${orphaned_packages}${NC}"
    echo -e "${BLUE}└─ Pacman cache size: ${YELLOW}${pacman_cache_size}${NC}"
    echo ""
}

# Update pacman database
update_db() {
    echo -e "${MAGENTA}${BOLD}❯ UPDATING PACKAGE DATABASE${NC}"
    echo -ne "${BLUE}└─ Refreshing pacman database...${NC} "
    pacman -Sy &>/dev/null &
    show_spinner $!
    echo ""
}

# Remove orphaned packages
remove_orphans() {
    echo -e "${MAGENTA}${BOLD}❯ ORPHANED PACKAGES${NC}"
    
    # Check if there are orphaned packages
    ORPHANS=$(pacman -Qtdq 2>/dev/null)
    if [ -z "$ORPHANS" ]; then
        echo -e "${BLUE}└─ No orphaned packages found${NC}"
    else
        local orphan_count=$(echo "$ORPHANS" | wc -l)
        echo -e "${BLUE}├─ Found ${YELLOW}${orphan_count}${BLUE} orphaned packages${NC}"
        
        # Only show first 5 packages if there are many
        if [ "$orphan_count" -gt 5 ]; then
            echo -e "${BLUE}│  ├─ $(echo "$ORPHANS" | head -n 5 | tr '\n' ' ')${NC}"
            echo -e "${BLUE}│  └─ ... and $(($orphan_count - 5)) more${NC}"
        else
            echo -e "${BLUE}│  └─ $(echo "$ORPHANS" | tr '\n' ' ')${NC}"
        fi
        
        echo -ne "${BLUE}└─ Removing orphaned packages...${NC} "
        pacman -Rns $(pacman -Qtdq) --noconfirm &>/dev/null &
        show_spinner $!
    fi
    echo ""
}

# Clean pacman cache
clean_pacman_cache() {
    echo -e "${MAGENTA}${BOLD}❯ PACKAGE CACHE CLEANUP${NC}"
    
    # Keep only one latest version of each package
    echo -ne "${BLUE}├─ Keeping only latest version of each package...${NC} "
    paccache -rk1 &>/dev/null &
    show_spinner $!
    
    # Remove all versions of uninstalled packages
    echo -ne "${BLUE}└─ Removing all versions of uninstalled packages...${NC} "
    paccache -ruk0 &>/dev/null &
    show_spinner $!
    
    echo ""
}

# Clean AUR helper cache (if installed)
clean_aur_cache() {
    echo -e "${MAGENTA}${BOLD}❯ AUR HELPER CLEANUP${NC}"
    
    if command -v yay &> /dev/null; then
        echo -ne "${BLUE}├─ Cleaning yay cache...${NC} "
        yay -Sc --noconfirm &>/dev/null &
        show_spinner $!
    else
        echo -e "${BLUE}├─ yay not installed, skipping${NC}"
    fi
    
    if command -v paru &> /dev/null; then
        echo -ne "${BLUE}└─ Cleaning paru cache...${NC} "
        paru -Sc --noconfirm &>/dev/null &
        show_spinner $!
    else
        echo -e "${BLUE}└─ paru not installed, skipping${NC}"
    fi
    
    echo ""
}

# Clean system cache and temporary files
clean_system_cache() {
    echo -e "${MAGENTA}${BOLD}❯ SYSTEM CACHE CLEANUP${NC}"
    
    # Clean user cache
    echo -ne "${BLUE}├─ Removing temporary user files...${NC} "
    {
        find /home -type f -name "*.tmp" -delete 2>/dev/null
        find /home -type f -name "*.bak" -delete 2>/dev/null
        find /home -type f -name "*~" -delete 2>/dev/null
    } &>/dev/null &
    show_spinner $!
    
    # Clean system tmp
    echo -ne "${BLUE}├─ Cleaning system temporary directory...${NC} "
    rm -rf /var/tmp/* 2>/dev/null &
    show_spinner $!
    
    # Clean journal logs
    echo -ne "${BLUE}└─ Cleaning old journal logs (keeping 7 days)...${NC} "
    journalctl --vacuum-time=7d &>/dev/null &
    show_spinner $!
    
    echo ""
}

# Clean systemd temporary files
clean_systemd_files() {
    echo -e "${MAGENTA}${BOLD}❯ SYSTEMD CLEANUP${NC}"
    
    echo -ne "${BLUE}└─ Resetting failed systemd units...${NC} "
    {
        systemctl --user reset-failed &>/dev/null
        systemctl reset-failed &>/dev/null
    } &
    show_spinner $!
    
    echo ""
}

# Update GRUB configuration
update_grub() {
    echo -e "${MAGENTA}${BOLD}❯ BOOTLOADER UPDATE${NC}"
    
    if [ -f /boot/grub/grub.cfg ]; then
        echo -ne "${BLUE}└─ Updating GRUB configuration...${NC} "
        grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null &
        show_spinner $!
    else
        echo -e "${BLUE}└─ GRUB configuration not found, skipping${NC}"
    fi
    
    echo ""
}

# Clean AUR build packages
clean_build_packages() {
    echo -e "${MAGENTA}${BOLD}❯ BUILD FILES CLEANUP${NC}"
    
    local cleanup_needed=false
    
    if [ -d /tmp/yay ]; then
        cleanup_needed=true
        echo -ne "${BLUE}├─ Cleaning yay build files...${NC} "
        rm -rf /tmp/yay/* 2>/dev/null &
        show_spinner $!
    fi
    
    if [ -d /var/tmp/pamac ]; then
        cleanup_needed=true
        echo -ne "${BLUE}├─ Cleaning pamac build files...${NC} "
        rm -rf /var/tmp/pamac/* 2>/dev/null &
        show_spinner $!
    fi
    
    if [ -d /tmp/makepkg ]; then
        cleanup_needed=true
        echo -ne "${BLUE}└─ Cleaning makepkg temporary files...${NC} "
        rm -rf /tmp/makepkg/* 2>/dev/null &
        show_spinner $!
    fi
    
    if [ "$cleanup_needed" = false ]; then
        echo -e "${BLUE}└─ No build files found, skipping${NC}"
    fi
    
    echo ""
}

# Clean browser cache files
clean_browser_cache() {
    echo -e "${MAGENTA}${BOLD}❯ BROWSER CACHE CLEANUP${NC}"
    echo -e "${YELLOW}Note: This works best when browsers are closed${NC}"
    
    # Firefox
    echo -ne "${BLUE}├─ Cleaning Firefox cache...${NC} "
    {
        find /home -type d -path "*/firefox/*/Cache" -exec rm -rf {} \; 2>/dev/null
        find /home -type d -path "*/firefox/*/cache2" -exec rm -rf {} \; 2>/dev/null
    } &>/dev/null &
    show_spinner $!
    
    # Chrome
    echo -ne "${BLUE}├─ Cleaning Chrome cache...${NC} "
    {
        find /home -type d -path "*/.config/google-chrome/*/Cache" -exec rm -rf {} \; 2>/dev/null
        find /home -type d -path "*/.cache/google-chrome" -exec rm -rf {} \; 2>/dev/null
    } &>/dev/null &
    show_spinner $!
    
    # Chromium
    echo -ne "${BLUE}└─ Cleaning Chromium cache...${NC} "
    find /home -type d -path "*/.cache/chromium" -exec rm -rf {} \; 2>/dev/null &
    show_spinner $!
    
    echo ""
}

# Clean development tool caches
clean_dev_caches() {
    echo -e "${MAGENTA}${BOLD}❯ DEVELOPMENT TOOL CACHES${NC}"
    
    # NPM cache
    if command -v npm &> /dev/null; then
        echo -ne "${BLUE}├─ Cleaning npm cache...${NC} "
        npm cache clean --force &>/dev/null &
        show_spinner $!
    else
        echo -e "${BLUE}├─ npm not installed, skipping${NC}"
    fi
    
    # Yarn cache
    if command -v yarn &> /dev/null; then
        echo -ne "${BLUE}├─ Cleaning yarn cache...${NC} "
        yarn cache clean &>/dev/null &
        show_spinner $!
    else
        echo -e "${BLUE}├─ yarn not installed, skipping${NC}"
    fi
    
    # Python cache
    echo -ne "${BLUE}└─ Cleaning Python cache files...${NC} "
    {
        find /home -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
        find /home -name "*.pyc" -delete 2>/dev/null
    } &>/dev/null &
    show_spinner $!
    
    echo ""
}

# Clean thumbnails
clean_thumbnails() {
    echo -e "${MAGENTA}${BOLD}❯ THUMBNAIL CACHE CLEANUP${NC}"
    
    echo -ne "${BLUE}└─ Removing thumbnail caches...${NC} "
    {
        find /home -type d -path "*/.thumbnails" -exec rm -rf {} \; 2>/dev/null
        find /home -type d -path "*/.cache/thumbnails" -exec rm -rf {} \; 2>/dev/null
    } &>/dev/null &
    show_spinner $!
    
    echo ""
}

# Display system information after cleaning
print_cleanup_results() {
    echo -e "${MAGENTA}${BOLD}❯ CLEANUP RESULTS${NC}"
    
    # Get disk usage after cleanup
    echo -e "${BLUE}├─ Current disk usage:${NC}"
    df -h / | grep -v "Filesystem" | awk '{print "│  └─ " $5 " used of " $2 " total (" $4 " available)"}'
    
    local total_packages=$(pacman -Q | wc -l)
    local orphaned_packages=$(pacman -Qtdq 2>/dev/null | wc -l || echo 0)
    local pacman_cache_size=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1)
    
    echo -e "${BLUE}├─ Current packages:${NC}"
    echo -e "│  ├─ Total installed: ${YELLOW}${total_packages}${NC}"
    echo -e "│  └─ Orphaned: ${YELLOW}${orphaned_packages}${NC}"
    echo -e "${BLUE}└─ Current pacman cache size: ${YELLOW}${pacman_cache_size}${NC}"
    echo ""
}

# Display completion message
print_completion() {
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║            ZeroCleaner completed successfully!             ║${NC}"
    echo -e "${GREEN}${BOLD}║                                                            ║${NC}"
    echo -e "${GREEN}${BOLD}║  Your Arch Linux system has been thoroughly cleaned and    ║${NC}"
    echo -e "${GREEN}${BOLD}║  optimized. Run this script periodically to maintain       ║${NC}"
    echo -e "${GREEN}${BOLD}║  optimal system performance and disk space.                ║${NC}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main function
main() {
    check_root
    print_banner
    print_system_info
    
    # Ask for confirmation
    echo -e "${YELLOW}${BOLD}Ready to clean your system?${NC} [Y/n] "
    read -r user_input
    
    if [[ "$user_input" =~ ^[Nn]$ ]]; then
        echo -e "${RED}${BOLD}Cleaning process canceled.${NC}"
        exit 0
    fi
    
    # Start cleaning operations
    update_db
    remove_orphans
    
    # Check for pacman-contrib package (for paccache)
    if ! command -v paccache &> /dev/null; then
        echo -e "${YELLOW}Installing required pacman-contrib package...${NC}"
        pacman -S pacman-contrib --noconfirm
    fi
    
    clean_pacman_cache
    clean_aur_cache
    clean_system_cache
    clean_systemd_files
    clean_build_packages
    clean_browser_cache
    clean_dev_caches
    clean_thumbnails
    update_grub
    
    # Show results
    print_cleanup_results
    print_completion
}

# Execute main function
main
