# Path to export Libs and Includes
OUTPUT_PATH="../SPIRV_Compiler/"

# Platform to build for
BUILD_PLATFORM="x64"

if [ -d "build" ]; then
  rm build -rf || { echo >&2 " failed. Some file could be in use."; exit 1; }
fi

# You can add or edit more cmake options for glslang building. Not all combinations are valid. Check for CMake erros.
# You can also add static CRT for msvc. Check CMake for the required options.
cmake -S . -B build -DCMAKE_GENERATOR_PLATFORM=${BUILD_PLATFORM} -DENABLE_HLSL=OFF -DENABLE_COMBINED_LIB=ON -DBUILD_TESTING=OFF -DENABLE_GLSLANG_BINARIES=OFF -DENABLE_OPT=OFF -DENABLE_SPVREMAPPER=OFF || { echo >&2 " failed."; exit 1; }
cd build

# Required because the path is relative to the ./build/ directory.
# DO NOT CHANGE THIS. Use the variable above.
RELATIVE_OUTPUT_PATH="../${OUTPUT_PATH}"

mkdir -p ${RELATIVE_OUTPUT_PATH}{Libs/{Debug,Release},Includes/glslang/{spirv,StandAlone,glslang}} || { echo >&2 " failed."; exit 1; }
cmake --build . --config Debug --target SPIRV_Compiler_genfile || { echo >&2 " failed."; exit 1; }
cp -v spirv/Debug/SPIRV_Compiler.lib ${RELATIVE_OUTPUT_PATH}Libs/Debug

cmake --build . --config Release --target SPIRV_Compiler_genfile || { echo >&2 " failed."; exit 1; }
cp -v spirv/Release/SPIRV_Compiler.lib ${RELATIVE_OUTPUT_PATH}Libs/Release


cp -r -v ../spirv/*.h ${RELATIVE_OUTPUT_PATH}Includes/glslang/spirv/
cp -r -v ../StandAlone/*.h ${RELATIVE_OUTPUT_PATH}Includes/glslang/StandAlone/

cd ../glslang/
find . -name '*.h' -exec cp -v --parents \{\} ${RELATIVE_OUTPUT_PATH}Includes/glslang/glslang/ \;
