import os
import plistlib
import uuid

def make_id():
    return uuid.uuid4().hex[:24].upper()

# Source and resource files
files = [
    ("App", "main.swift", "sourcecode.swift", "source"),
    ("App", "AppDelegate.swift", "sourcecode.swift", "source"),
    ("App", "LaunchAtLoginManager.swift", "sourcecode.swift", "source"),
    ("Models", "CPUMetrics.swift", "sourcecode.swift", "source"),
    ("Models", "DisplayPreferences.swift", "sourcecode.swift", "source"),
    ("Services", "AppLogger.swift", "sourcecode.swift", "source"),
    ("Services", "SystemInfoService.swift", "sourcecode.swift", "source"),
    ("Services", "CPUMonitorEngine.swift", "sourcecode.swift", "source"),
    ("Views", "CPUOverviewSection.swift", "sourcecode.swift", "source"),
    ("Views", "PerCoreSection.swift", "sourcecode.swift", "source"),
    ("Views", "SystemInfoSection.swift", "sourcecode.swift", "source"),
    ("Views", "DropdownView.swift", "sourcecode.swift", "source"),
    ("Resources", "Info.plist", "text.plist.xml", "none"),
    ("Resources", "CPUMonitor.entitlements", "text.plist.entitlements", "none"),
    ("Resources", "AppIcon.icns", "image.icns", "resource"),
]

objects = {}

file_refs_by_folder = {}
source_build_file_ids = []
resource_build_file_ids = []

for folder, name, ftype, role in files:
    f_ref_id = make_id()
    objects[f_ref_id] = {
        "isa": "PBXFileReference",
        "lastKnownFileType": ftype,
        "name": name,
        "path": f"{folder}/{name}",
        "sourceTree": "<group>"
    }
    file_refs_by_folder.setdefault(folder, []).append(f_ref_id)
    
    if role == "source":
        b_file_id = make_id()
        objects[b_file_id] = {
            "isa": "PBXBuildFile",
            "fileRef": f_ref_id
        }
        source_build_file_ids.append(b_file_id)
    elif role == "resource":
        b_file_id = make_id()
        objects[b_file_id] = {
            "isa": "PBXBuildFile",
            "fileRef": f_ref_id
        }
        resource_build_file_ids.append(b_file_id)

# App product file ref
product_ref_id = make_id()
objects[product_ref_id] = {
    "isa": "PBXFileReference",
    "explicitFileType": "wrapper.application",
    "includeInIndex": "0",
    "path": "CPUMonitor.app",
    "sourceTree": "BUILT_PRODUCTS_DIR"
}

# Groups for subfolders
folder_group_ids = []
for folder in ["App", "Models", "Services", "Views", "Resources"]:
    grp_id = make_id()
    objects[grp_id] = {
        "isa": "PBXGroup",
        "children": file_refs_by_folder.get(folder, []),
        "name": folder,
        "sourceTree": "<group>"
    }
    folder_group_ids.append(grp_id)

# CPUMonitor Group
cpu_group_id = make_id()
objects[cpu_group_id] = {
    "isa": "PBXGroup",
    "children": folder_group_ids,
    "path": "CPUMonitor",
    "sourceTree": "<group>"
}

# Products Group
products_group_id = make_id()
objects[products_group_id] = {
    "isa": "PBXGroup",
    "children": [product_ref_id],
    "name": "Products",
    "sourceTree": "<group>"
}

# Main Group
main_group_id = make_id()
objects[main_group_id] = {
    "isa": "PBXGroup",
    "children": [cpu_group_id, products_group_id],
    "sourceTree": "<group>"
}

# Build Phases
sources_phase_id = make_id()
objects[sources_phase_id] = {
    "isa": "PBXSourcesBuildPhase",
    "buildActionMask": "2147483647",
    "files": source_build_file_ids,
    "runOnlyForDeploymentPostprocessing": "0"
}

frameworks_phase_id = make_id()
objects[frameworks_phase_id] = {
    "isa": "PBXFrameworksBuildPhase",
    "buildActionMask": "2147483647",
    "files": [],
    "runOnlyForDeploymentPostprocessing": "0"
}

resources_phase_id = make_id()
objects[resources_phase_id] = {
    "isa": "PBXResourcesBuildPhase",
    "buildActionMask": "2147483647",
    "files": resource_build_file_ids,
    "runOnlyForDeploymentPostprocessing": "0"
}

# Target Configurations
cfg_debug_target = make_id()
objects[cfg_debug_target] = {
    "isa": "XCBuildConfiguration",
    "buildSettings": {
        "CODE_SIGN_ENTITLEMENTS": "CPUMonitor/Resources/CPUMonitor.entitlements",
        "CODE_SIGN_IDENTITY": "-",
        "CODE_SIGN_STYLE": "Manual",
        "COMBINE_HIDPI_IMAGES": "YES",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "CPUMonitor/Resources/Info.plist",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"],
        "MARKETING_VERSION": "1.0.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.antigravity.cpumonitor",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "5.0"
    },
    "name": "Debug"
}

cfg_release_target = make_id()
objects[cfg_release_target] = {
    "isa": "XCBuildConfiguration",
    "buildSettings": {
        "CODE_SIGN_ENTITLEMENTS": "CPUMonitor/Resources/CPUMonitor.entitlements",
        "CODE_SIGN_IDENTITY": "-",
        "CODE_SIGN_STYLE": "Manual",
        "COMBINE_HIDPI_IMAGES": "YES",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "CPUMonitor/Resources/Info.plist",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"],
        "MARKETING_VERSION": "1.0.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.antigravity.cpumonitor",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "5.0"
    },
    "name": "Release"
}

cfg_list_target = make_id()
objects[cfg_list_target] = {
    "isa": "XCConfigurationList",
    "buildConfigurations": [cfg_debug_target, cfg_release_target],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release"
}

# Native Target
target_id = make_id()
objects[target_id] = {
    "isa": "PBXNativeTarget",
    "buildConfigurationList": cfg_list_target,
    "buildPhases": [sources_phase_id, frameworks_phase_id, resources_phase_id],
    "buildRules": [],
    "dependencies": [],
    "name": "CPUMonitor",
    "productName": "CPUMonitor",
    "productReference": product_ref_id,
    "productType": "com.apple.product-type.application"
}

# Project Configurations
cfg_debug_proj = make_id()
objects[cfg_debug_proj] = {
    "isa": "XCBuildConfiguration",
    "buildSettings": {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "ARCHS": "$(ARCHS_STANDARD)",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "MACOSX_DEPLOYMENT_TARGET": "13.0",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "macosx",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
    },
    "name": "Debug"
}

cfg_release_proj = make_id()
objects[cfg_release_proj] = {
    "isa": "XCBuildConfiguration",
    "buildSettings": {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "ARCHS": "$(ARCHS_STANDARD)",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "ENABLE_NS_ASSERTIONS": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "MACOSX_DEPLOYMENT_TARGET": "13.0",
        "SDKROOT": "macosx",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "-O"
    },
    "name": "Release"
}

cfg_list_proj = make_id()
objects[cfg_list_proj] = {
    "isa": "XCConfigurationList",
    "buildConfigurations": [cfg_debug_proj, cfg_release_proj],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release"
}

# PBXProject
proj_id = make_id()
objects[proj_id] = {
    "isa": "PBXProject",
    "attributes": {
        "BuildIndependentTargetsInParallel": "YES",
        "LastSwiftUpdateCheck": "1600",
        "LastUpgradeCheck": "1600",
        "TargetAttributes": {
            target_id: {
                "CreatedOnToolsVersion": "16.0"
            }
        }
    },
    "buildConfigurationList": cfg_list_proj,
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "en",
    "hasScannedForEncodings": "0",
    "knownRegions": ["en", "Base"],
    "mainGroup": main_group_id,
    "productRefGroup": products_group_id,
    "projectDirPath": "",
    "projectRoot": "",
    "targets": [target_id]
}

project_dict = {
    "archiveVersion": "1",
    "classes": {},
    "objectVersion": "56",
    "objects": objects,
    "rootObject": proj_id
}

os.makedirs("CPUMonitor.xcodeproj", exist_ok=True)
with open("CPUMonitor.xcodeproj/project.pbxproj", "wb") as f:
    plistlib.dump(project_dict, f, fmt=plistlib.FMT_XML)

print("Generated valid XML PBXProject with AppIcon.icns in Resources!")
