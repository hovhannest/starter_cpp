import os
import sys
import filecmp

def check_clang_tidy_tests():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    template_file = os.path.join(root_dir, ".clang-tidy-tests")

    if not os.path.exists(template_file):
        print(f"Error: Template file {template_file} not found.")
        return 1

    mismatches = []

    for root, dirs, files in os.walk(root_dir):
        # Skip common build/dependency directories to speed up
        if any(skip in root for skip in [".git", "build", ".conan2"]):
            continue

        if ".clang-tidy" in files:
            file_path = os.path.join(root, ".clang-tidy")
            # Check if this .clang-tidy is inside a 'tests' or 'test' directory (nested or direct)
            relative_path = os.path.relpath(root, root_dir)
            path_parts = relative_path.split(os.sep)

            if any(part in ["tests", "test"] for part in path_parts):
                if not filecmp.cmp(template_file, file_path, shallow=False):
                    mismatches.append(file_path)

    if mismatches:
        print("Error: The following .clang-tidy files in tests folders do NOT match .clang-tidy-tests:")
        for m in mismatches:
            print(f"  - {os.path.relpath(m, root_dir)}")
        print("\nPlease update them to match the root .clang-tidy-tests file.")
        return 1

    print("Checking .clang-tidy consistency in tests folders... OK")
    return 0

if __name__ == "__main__":
    sys.exit(check_clang_tidy_tests())
