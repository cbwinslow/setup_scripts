#!/usr/bin/env python3
"""
Name: system_config_generator.py
Date: 2025-02-17
Purpose: Generate a YAML configuration file representing the current state of the machine.
Function: Gathers system information including OS details, CPU, memory, disk, network, and environment variables.
Inputs: None (system information is automatically gathered)
Outputs: A YAML file (default: system_config.yaml) containing the system configuration.
Description: This script collects system information using Python's standard libraries and the psutil library (if available).
             It then writes the gathered information to a YAML file for later use or configuration management.
File Path: <your_file_path/system_config_generator.py>
"""

import os
import sys
import platform
import datetime

# Attempt to import psutil for hardware and system metrics
try:
    import psutil
except ImportError:
    psutil = None

# Attempt to import PyYAML for YAML output
try:
    import yaml
except ImportError:
    print("PyYAML is not installed. Please install it using 'pip install PyYAML'")
    sys.exit(1)

class SystemConfigCollector:
    """
    Class to collect system configuration details and output them to a YAML file.
    """
    def __init__(self):
        """
        Initialize the SystemConfigCollector object.
        """
        pass  # No specific initialization required

    def gather_info(self):
        """
        Gather system configuration details.

        Returns:
            dict: A dictionary containing system information.
        """
        config = {}

        # OS Information
        config['os'] = {
            'system': platform.system(),
            'release': platform.release(),
            'version': platform.version(),
            'machine': platform.machine(),
            'processor': platform.processor()
        }

        # CPU Information
        if psutil:
            try:
                cpu_freq = psutil.cpu_freq()
                config['cpu'] = {
                    'physical_cores': psutil.cpu_count(logical=False),
                    'total_cores': psutil.cpu_count(logical=True),
                    'max_frequency_mhz': cpu_freq.max if cpu_freq else None,
                    'min_frequency_mhz': cpu_freq.min if cpu_freq else None,
                    'current_frequency_mhz': cpu_freq.current if cpu_freq else None,
                    'cpu_usage_percent': psutil.cpu_percent(interval=1)
                }
            except Exception as e:
                config['cpu'] = f"Error collecting CPU info: {e}"
        else:
            config['cpu'] = "psutil module not available"

        # Memory Information
        if psutil:
            try:
                virtual_mem = psutil.virtual_memory()
                config['memory'] = {
                    'total_mb': round(virtual_mem.total / (1024 ** 2), 2),
                    'available_mb': round(virtual_mem.available / (1024 ** 2), 2),
                    'used_mb': round(virtual_mem.used / (1024 ** 2), 2),
                    'percentage': virtual_mem.percent
                }
            except Exception as e:
                config['memory'] = f"Error collecting memory info: {e}"
        else:
            config['memory'] = "psutil module not available"

        # Disk Information
        if psutil:
            try:
                partitions = psutil.disk_partitions()
                disk_info = []
                for partition in partitions:
                    try:
                        usage = psutil.disk_usage(partition.mountpoint)
                        partition_data = {
                            'device': partition.device,
                            'mountpoint': partition.mountpoint,
                            'fstype': partition.fstype,
                            'opts': partition.opts,
                            'total_mb': round(usage.total / (1024 ** 2), 2),
                            'used_mb': round(usage.used / (1024 ** 2), 2),
                            'free_mb': round(usage.free / (1024 ** 2), 2),
                            'percentage': usage.percent
                        }
                    except Exception as e:
                        partition_data = {
                            'device': partition.device,
                            'error': str(e)
                        }
                    disk_info.append(partition_data)
                config['disk'] = disk_info
            except Exception as e:
                config['disk'] = f"Error collecting disk info: {e}"
        else:
            config['disk'] = "psutil module not available"

        # Network Information
        if psutil:
            try:
                net_info = {}
                interfaces = psutil.net_if_addrs()
                for interface, addrs in interfaces.items():
                    addr_list = []
                    for addr in addrs:
                        addr_list.append({
                            'family': str(addr.family),
                            'address': addr.address,
                            'netmask': addr.netmask,
                            'broadcast': addr.broadcast,
                            'ptp': addr.ptp
                        })
                    net_info[interface] = addr_list
                config['network'] = net_info
            except Exception as e:
                config['network'] = f"Error collecting network info: {e}"
        else:
            config['network'] = "psutil module not available"

        # Environment Variables
        try:
            config['environment'] = dict(os.environ)
        except Exception as e:
            config['environment'] = f"Error collecting environment variables: {e}"

        # Timestamp of configuration generation
        config['timestamp'] = datetime.datetime.now().isoformat()

        return config

    def write_config(self, config, file_path="system_config.yaml"):
        """
        Write the configuration dictionary to a YAML file.

        Args:
            config (dict): The configuration dictionary.
            file_path (str): The file path to save the YAML file.
        """
        try:
            with open(file_path, 'w') as file:
                yaml.dump(config, file, default_flow_style=False, sort_keys=False)
            print(f"Configuration file successfully saved to {file_path}")
        except Exception as e:
            print(f"Failed to write configuration file: {e}")

def main():
    """
    Main function to generate and write the system configuration.
    """
    try:
        collector = SystemConfigCollector()
        config_data = collector.gather_info()
        # Optionally, allow file path to be specified via command-line argument
        output_file = "system_config.yaml"
        if len(sys.argv) > 1:
            output_file = sys.argv[1]
        collector.write_config(config_data, file_path=output_file)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
