#!/usr/bin/env python3
"""Generate Xcode project.pbxproj for NolgoManyDJ"""

import hashlib
import os

def make_uuid(name):
    """Generate a deterministic 24-char hex UUID from a name."""
    h = hashlib.md5(name.encode()).hexdigest().upper()
    return h[:24]

# All Swift source files (relative to project root)
swift_files = [
    "NolgoManyDJ/App/NolgoManyDJApp.swift",
    "NolgoManyDJ/Data/MockData.swift",
    "NolgoManyDJ/Models/Course.swift",
    "NolgoManyDJ/Models/Store.swift",
    "NolgoManyDJ/Models/UserModels.swift",
    "NolgoManyDJ/Models/OwnerAnalytics.swift",
    "NolgoManyDJ/Services/DataService.swift",
    "NolgoManyDJ/Services/SupabaseService.swift",
    "NolgoManyDJ/Services/KakaoImageService.swift",
    "NolgoManyDJ/Utils/Theme.swift",
    "NolgoManyDJ/ViewModels/AppState.swift",
    "NolgoManyDJ/Views/Components/CommonComponents.swift",
    "NolgoManyDJ/Views/Components/CourseCard.swift",
    "NolgoManyDJ/Views/Components/StoreCard.swift",
    "NolgoManyDJ/Views/Courses/CourseDetailView.swift",
    "NolgoManyDJ/Views/Courses/CoursesView.swift",
    "NolgoManyDJ/Views/Home/HomeView.swift",
    "NolgoManyDJ/Views/Map/MapExploreView.swift",
    "NolgoManyDJ/Views/MyPage/MyPageView.swift",
    "NolgoManyDJ/Views/Onboarding/OnboardingView.swift",
    "NolgoManyDJ/Views/Owner/OwnerDashboardView.swift",
    "NolgoManyDJ/Views/Saved/SavedView.swift",
    "NolgoManyDJ/Views/Stores/StoreDetailView.swift",
]

# UUIDs
PROJECT_UUID = make_uuid("project")
MAIN_GROUP_UUID = make_uuid("mainGroup")
SOURCES_GROUP_UUID = make_uuid("sourcesGroup")
FRAMEWORKS_GROUP_UUID = make_uuid("frameworksGroup")
PRODUCTS_GROUP_UUID = make_uuid("productsGroup")
APP_GROUP_UUID = make_uuid("appGroup")
MODELS_GROUP_UUID = make_uuid("modelsGroup")
VIEWS_GROUP_UUID = make_uuid("viewsGroup")
VIEWMODELS_GROUP_UUID = make_uuid("viewmodelsGroup")
SERVICES_GROUP_UUID = make_uuid("servicesGroup")
DATA_GROUP_UUID = make_uuid("dataGroup")
UTILS_GROUP_UUID = make_uuid("utilsGroup")
COMPONENTS_GROUP_UUID = make_uuid("componentsGroup")
HOME_GROUP_UUID = make_uuid("homeGroup")
MAP_GROUP_UUID = make_uuid("mapGroup")
COURSES_GROUP_UUID = make_uuid("coursesViewGroup")
STORES_GROUP_UUID = make_uuid("storesGroup")
SAVED_GROUP_UUID = make_uuid("savedGroup")
MYPAGE_GROUP_UUID = make_uuid("mypageGroup")
ONBOARDING_GROUP_UUID = make_uuid("onboardingGroup")
OWNER_GROUP_UUID = make_uuid("ownerGroup")
ASSETS_GROUP_UUID = make_uuid("assetsGroup")

TARGET_UUID = make_uuid("target")
BUILD_CONFIG_LIST_PROJECT = make_uuid("buildConfigListProject")
BUILD_CONFIG_LIST_TARGET = make_uuid("buildConfigListTarget")
BUILD_CONFIG_DEBUG_PROJECT = make_uuid("buildConfigDebugProject")
BUILD_CONFIG_RELEASE_PROJECT = make_uuid("buildConfigReleaseProject")
BUILD_CONFIG_DEBUG_TARGET = make_uuid("buildConfigDebugTarget")
BUILD_CONFIG_RELEASE_TARGET = make_uuid("buildConfigReleaseTarget")
SOURCES_BUILD_PHASE = make_uuid("sourcesBuildPhase")
FRAMEWORKS_BUILD_PHASE = make_uuid("frameworksBuildPhase")
RESOURCES_BUILD_PHASE = make_uuid("resourcesBuildPhase")
PRODUCT_REF_UUID = make_uuid("productRef")

# Generate file references and build files
file_refs = {}
build_files = {}
for f in swift_files:
    name = os.path.basename(f)
    ref_uuid = make_uuid("ref_" + f)
    build_uuid = make_uuid("build_" + f)
    file_refs[f] = {"uuid": ref_uuid, "name": name, "path": f}
    build_files[f] = {"uuid": build_uuid, "fileRef": ref_uuid}

# Assets reference
ASSETS_REF_UUID = make_uuid("ref_assets")
ASSETS_BUILD_UUID = make_uuid("build_assets")

# Group mapping: file path -> group
def get_group(path):
    if "/App/" in path: return "App"
    if "/Models/" in path: return "Models"
    if "/Components/" in path: return "Components"
    if "/Home/" in path: return "Home"
    if "/Map/" in path: return "Map"
    if "/Courses/" in path: return "Courses"
    if "/Stores/" in path: return "Stores"
    if "/Saved/" in path: return "Saved"
    if "/MyPage/" in path: return "MyPage"
    if "/Onboarding/" in path: return "Onboarding"
    if "/Owner/" in path: return "Owner"
    if "/ViewModels/" in path: return "ViewModels"
    if "/Services/" in path: return "Services"
    if "/Data/" in path: return "Data"
    if "/Utils/" in path: return "Utils"
    return "Sources"

group_files = {}
for f in swift_files:
    g = get_group(f)
    if g not in group_files:
        group_files[g] = []
    group_files[g].append(f)

GROUP_UUIDS = {
    "App": APP_GROUP_UUID,
    "Models": MODELS_GROUP_UUID,
    "Views": VIEWS_GROUP_UUID,
    "ViewModels": VIEWMODELS_GROUP_UUID,
    "Services": SERVICES_GROUP_UUID,
    "Data": DATA_GROUP_UUID,
    "Utils": UTILS_GROUP_UUID,
    "Components": COMPONENTS_GROUP_UUID,
    "Home": HOME_GROUP_UUID,
    "Map": MAP_GROUP_UUID,
    "Courses": COURSES_GROUP_UUID,
    "Stores": STORES_GROUP_UUID,
    "Saved": SAVED_GROUP_UUID,
    "MyPage": MYPAGE_GROUP_UUID,
    "Onboarding": ONBOARDING_GROUP_UUID,
    "Owner": OWNER_GROUP_UUID,
}

pbxproj = """// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
"""

# Build files
for f in swift_files:
    bf = build_files[f]
    name = os.path.basename(f)
    pbxproj += f'\t\t{bf["uuid"]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {bf["fileRef"]} /* {name} */; }};\n'

pbxproj += f'\t\t{ASSETS_BUILD_UUID} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ASSETS_REF_UUID} /* Assets.xcassets */; }};\n'

pbxproj += """/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""

# File references
for f in swift_files:
    fr = file_refs[f]
    pbxproj += f'\t\t{fr["uuid"]} /* {fr["name"]} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fr["name"]}; sourceTree = "<group>"; }};\n'

pbxproj += f'\t\t{ASSETS_REF_UUID} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};\n'
pbxproj += f'\t\t{PRODUCT_REF_UUID} /* NolgoManyDJ.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = NolgoManyDJ.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n'

pbxproj += """/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
"""
pbxproj += f"""\t\t{FRAMEWORKS_BUILD_PHASE} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
"""

# Main group
pbxproj += f"""\t\t{MAIN_GROUP_UUID} = {{
			isa = PBXGroup;
			children = (
				{SOURCES_GROUP_UUID} /* NolgoManyDJ */,
				{PRODUCTS_GROUP_UUID} /* Products */,
			);
			sourceTree = "<group>";
		}};
"""

# Products group
pbxproj += f"""\t\t{PRODUCTS_GROUP_UUID} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{PRODUCT_REF_UUID} /* NolgoManyDJ.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
"""

# Source group (NolgoManyDJ/)
pbxproj += f"""\t\t{SOURCES_GROUP_UUID} /* NolgoManyDJ */ = {{
			isa = PBXGroup;
			children = (
				{APP_GROUP_UUID} /* App */,
				{MODELS_GROUP_UUID} /* Models */,
				{VIEWS_GROUP_UUID} /* Views */,
				{VIEWMODELS_GROUP_UUID} /* ViewModels */,
				{SERVICES_GROUP_UUID} /* Services */,
				{DATA_GROUP_UUID} /* Data */,
				{UTILS_GROUP_UUID} /* Utils */,
				{ASSETS_REF_UUID} /* Assets.xcassets */,
			);
			path = NolgoManyDJ;
			sourceTree = "<group>";
		}};
"""

# Views group
pbxproj += f"""\t\t{VIEWS_GROUP_UUID} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{COMPONENTS_GROUP_UUID} /* Components */,
				{ONBOARDING_GROUP_UUID} /* Onboarding */,
				{HOME_GROUP_UUID} /* Home */,
				{MAP_GROUP_UUID} /* Map */,
				{COURSES_GROUP_UUID} /* Courses */,
				{STORES_GROUP_UUID} /* Stores */,
				{SAVED_GROUP_UUID} /* Saved */,
				{MYPAGE_GROUP_UUID} /* MyPage */,
				{OWNER_GROUP_UUID} /* Owner */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
"""

# Each subgroup
subgroups = {
    "App": ("App", APP_GROUP_UUID),
    "Models": ("Models", MODELS_GROUP_UUID),
    "ViewModels": ("ViewModels", VIEWMODELS_GROUP_UUID),
    "Services": ("Services", SERVICES_GROUP_UUID),
    "Data": ("Data", DATA_GROUP_UUID),
    "Utils": ("Utils", UTILS_GROUP_UUID),
    "Components": ("Components", COMPONENTS_GROUP_UUID),
    "Onboarding": ("Onboarding", ONBOARDING_GROUP_UUID),
    "Home": ("Home", HOME_GROUP_UUID),
    "Map": ("Map", MAP_GROUP_UUID),
    "Courses": ("Courses", COURSES_GROUP_UUID),
    "Stores": ("Stores", STORES_GROUP_UUID),
    "Saved": ("Saved", SAVED_GROUP_UUID),
    "MyPage": ("MyPage", MYPAGE_GROUP_UUID),
    "Owner": ("Owner", OWNER_GROUP_UUID),
}

for group_name, (path_name, uuid) in subgroups.items():
    files_in_group = group_files.get(group_name, [])
    children = ",\n".join([f'\t\t\t\t{file_refs[f]["uuid"]} /* {os.path.basename(f)} */' for f in files_in_group])
    pbxproj += f"""\t\t{uuid} /* {group_name} */ = {{
			isa = PBXGroup;
			children = (
{children}
			);
			path = {path_name};
			sourceTree = "<group>";
		}};
"""

pbxproj += """/* End PBXGroup section */

/* Begin PBXNativeTarget section */
"""

pbxproj += f"""\t\t{TARGET_UUID} /* NolgoManyDJ */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {BUILD_CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "NolgoManyDJ" */;
			buildPhases = (
				{SOURCES_BUILD_PHASE} /* Sources */,
				{FRAMEWORKS_BUILD_PHASE} /* Frameworks */,
				{RESOURCES_BUILD_PHASE} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = NolgoManyDJ;
			productName = NolgoManyDJ;
			productReference = {PRODUCT_REF_UUID} /* NolgoManyDJ.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
"""

pbxproj += f"""\t\t{PROJECT_UUID} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1540;
				LastUpgradeCheck = 1540;
				TargetAttributes = {{
					{TARGET_UUID} = {{
						CreatedOnToolsVersion = 15.4;
					}};
				}};
			}};
			buildConfigurationList = {BUILD_CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject "NolgoManyDJ" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = ko;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				ko,
				Base,
			);
			mainGroup = {MAIN_GROUP_UUID};
			productRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{TARGET_UUID} /* NolgoManyDJ */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
"""

pbxproj += f"""\t\t{RESOURCES_BUILD_PHASE} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{ASSETS_BUILD_UUID} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
"""

build_file_entries = ",\n".join([f'\t\t\t\t{build_files[f]["uuid"]} /* {os.path.basename(f)} in Sources */' for f in swift_files])

pbxproj += f"""\t\t{SOURCES_BUILD_PHASE} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{build_file_entries},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
"""

# Debug config - Project level
pbxproj += f"""\t\t{BUILD_CONFIG_DEBUG_PROJECT} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
"""

# Release config - Project level
pbxproj += f"""\t\t{BUILD_CONFIG_RELEASE_PROJECT} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
"""

# Debug config - Target level
pbxproj += f"""\t\t{BUILD_CONFIG_DEBUG_TARGET} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "놀거많은대?전";
				INFOPLIST_KEY_KAKAO_REST_API_KEY = "$(KAKAO_REST_API_KEY)";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait";
				INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "현재 위치 기반으로 주변 가게를 찾아드려요";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				KAKAO_REST_API_KEY = "";
				PRODUCT_BUNDLE_IDENTIFIER = com.nolgomanydj.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
"""

# Release config - Target level
pbxproj += f"""\t\t{BUILD_CONFIG_RELEASE_TARGET} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "놀거많은대?전";
				INFOPLIST_KEY_KAKAO_REST_API_KEY = "$(KAKAO_REST_API_KEY)";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait";
				INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "현재 위치 기반으로 주변 가게를 찾아드려요";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				KAKAO_REST_API_KEY = "";
				PRODUCT_BUNDLE_IDENTIFIER = com.nolgomanydj.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
"""

pbxproj += """/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
"""

pbxproj += f"""\t\t{BUILD_CONFIG_LIST_PROJECT} /* Build configuration list for PBXProject "NolgoManyDJ" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{BUILD_CONFIG_DEBUG_PROJECT} /* Debug */,
				{BUILD_CONFIG_RELEASE_PROJECT} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{BUILD_CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "NolgoManyDJ" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{BUILD_CONFIG_DEBUG_TARGET} /* Debug */,
				{BUILD_CONFIG_RELEASE_TARGET} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
"""

pbxproj += f"""	}};
	rootObject = {PROJECT_UUID} /* Project object */;
}}
"""

# Write the file
output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "NolgoManyDJ.xcodeproj", "project.pbxproj")
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, "w") as f:
    f.write(pbxproj)

print(f"Generated: {output_path}")
print(f"Total Swift files: {len(swift_files)}")
