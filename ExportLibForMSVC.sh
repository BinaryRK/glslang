rm build -rf
cmake -S . -B build -DENABLE_HLSL=OFF -DBUILD_TESTING=OFF -DENABLE_GLSLANG_BINARIES=OFF -DENABLE_OPT=OFF -DENABLE_SPVREMAPPER=OFF -DCMAKE_GENERATOR_PLATFORM=x64 ||  { echo >&2 " failed."; exit 1; }
cd build

# Relative to ./build/ directory
OUTPUT_PATH="../../SPIRV_Compiler/"

mkdir -p ${OUTPUT_PATH}{Libs/{Debug,Release},Includes/glslang/{spirv,StandAlone,glslang}} || { echo >&2 " failed."; exit 1; }
cmake --build . --config Debug --target SPIRV_Compiler_genfile || { echo >&2 " failed."; exit 1; }
cp -v spirv/Debug/SPIRV_Compiler.lib ${OUTPUT_PATH}Libs/Debug

cmake --build . --config Release --target SPIRV_Compiler_genfile || { echo >&2 " failed."; exit 1; }
cp -v spirv/Release/SPIRV_Compiler.lib ${OUTPUT_PATH}Libs/Release


cp -r -v ../spirv/*.h ${OUTPUT_PATH}Includes/glslang/spirv/
cp -r -v ../StandAlone/*.h ${OUTPUT_PATH}Includes/glslang/StandAlone/

cd ../glslang/
find . -name '*.h' -exec cp -v --parents \{\} ${OUTPUT_PATH}Includes/glslang/glslang/ \;
