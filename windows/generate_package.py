import os
import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description='Generate WiX Package.wxs for App Market')
    parser.add_argument('--release-dir', default='build/windows/x64/runner/Release',
                        help='Path to Flutter Windows Release build directory')
    parser.add_argument('--output', default='windows/Package.wxs',
                        help='Output Package.wxs path')
    args = parser.parse_args()

    release_dir = os.path.abspath(args.release_dir)
    source_dir = release_dir
    data_dir = os.path.join(release_dir, 'data')

    if not os.path.isdir(data_dir):
        print(f'Error: data directory not found at {data_dir}')
        sys.exit(1)

    # Collect data files
    files = []
    for root, dirs, filenames in os.walk(data_dir):
        for f in filenames:
            full = os.path.join(root, f)
            rel = os.path.relpath(full, data_dir)
            files.append((rel.replace('\\', '/'), full.replace('\\', '/')))

    # Collect DLL files in Release directory (excluding data folder and hardcoded files)
    hardcoded_files = {'app_market.exe', 'flutter_windows.dll'}
    dll_files = []
    for f in os.listdir(release_dir):
        if f.lower().endswith('.dll') and os.path.isfile(os.path.join(release_dir, f)) and f not in hardcoded_files:
            dll_files.append(f)

    dirs_map = {'DataFolder': []}
    component_ids = []

    for rel, full in files:
        parts = rel.split('/')
        parent = 'DataFolder'
        for i, p in enumerate(parts[:-1]):
            path_prefix = '_'.join(parts[:i+1]).replace('-','_').replace(' ','_')
            dir_id = 'D_' + path_prefix
            found = False
            for item in dirs_map.get(parent, []):
                if item['type'] == 'dir' and item['id'] == dir_id:
                    found = True
                    break
            if not found:
                dirs_map.setdefault(parent, []).append({'type':'dir','name':p,'id':dir_id})
                dirs_map[dir_id] = []
            parent = dir_id
        cid = 'C_' + rel.replace('/','_').replace('.','_').replace('-','_')
        component_ids.append(cid)
        dirs_map[parent].append({'type':'file','rel':rel,'full':full,'cid':cid})

    def gen_ref(dir_id, indent):
        out = ''
        for item in dirs_map.get(dir_id, []):
            if item['type'] == 'dir':
                out += f'{indent}<Directory Id="{item["id"]}" Name="{item["name"]}">\n'
                out += gen_ref(item['id'], indent + '  ')
                out += f'{indent}</Directory>\n'
            else:
                cid = item['cid']
                src = item['rel'].replace('\\', '/')
                out += f'{indent}<Component Id="{cid}" Guid="*"><File Id="F_{cid}" Source="$(var.SourceDir)/data/{src}" KeyPath="yes" /></Component>\n'
        return out

    def gen_component_group():
        out = '    <ComponentGroup Id="DataComponents">\n'
        for cid in component_ids:
            out += f'      <ComponentRef Id="{cid}" />\n'
        out += '    </ComponentGroup>\n'
        return out

    data_tree = gen_ref('DataFolder', '        ')
    component_group = gen_component_group()

    # Generate DLL components for AppComponents
    app_components_dlls = ''
    for dll in dll_files:
        cid = 'C_' + dll.replace('.', '_').replace('-', '_')
        app_components_dlls += f'      <Component Id="{cid}" Guid="*">\n'
        app_components_dlls += f'        <File Id="F_{cid}" Source="$(var.SourceDir)/{dll}" />\n'
        app_components_dlls += f'      </Component>\n'

    pkg = f'''<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">

  <Package Name="App Market"
           Manufacturer="AppPlatform"
           Version="1.0.0.0"
           UpgradeCode="8A6B2C1D-E3F4-4A5B-9C7D-1E2F3A4B5C6D"
           Language="1033">

    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." />

    <MediaTemplate EmbedCab="yes" />

    <Icon Id="AppIcon" SourceFile="$(var.SourceDir)/app_icon.ico" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon" />

    <Feature Id="Main">
      <ComponentGroupRef Id="AppComponents" />
      <ComponentGroupRef Id="DataComponents" />
      <ComponentRef Id="DesktopShortcutComponent" />
    </Feature>

    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory Id="INSTALLFOLDER" Name="App Market">
        <Directory Id="DataFolder" Name="data">
{data_tree}        </Directory>
      </Directory>
    </StandardDirectory>

    <StandardDirectory Id="DesktopFolder">
      <Component Id="DesktopShortcutComponent" Guid="B2C3D4E5-F6A7-4890-9D1E-EF2345678901">
        <Shortcut Id="DesktopShortcut"
                  Name="App Market"
                  Description="App Market Desktop App"
                  Target="[!AppMarketExe]"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="AppIcon" />
        <RegistryValue Root="HKCU" Key="Software\\AppPlatform\\AppMarket" Name="installed" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </StandardDirectory>

    <ComponentGroup Id="AppComponents" Directory="INSTALLFOLDER">
      <Component Id="MainExecutable" Guid="*">
        <File Id="AppMarketExe" Source="$(var.SourceDir)/app_market.exe" KeyPath="yes" />
      </Component>
      <Component Id="FlutterEngine" Guid="*">
        <File Id="FlutterDll" Source="$(var.SourceDir)/flutter_windows.dll" />
      </Component>
{app_components_dlls}    </ComponentGroup>

{component_group}  </Package>
</Wix>
'''

    output_path = args.output
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(pkg)
    print(f'Generated {output_path} with {len(files)} data files and {len(dll_files)} DLL files')

if __name__ == '__main__':
    main()
