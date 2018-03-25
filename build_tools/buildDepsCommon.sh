DEPS_FLAGS=""
doBuild=true
if [[ "$1" == "-nobuild" ]]; then
    doBuild=false
    DEPS_FLAGS+="-nobuild"
    shift
fi

DEPS_BUILD=$PWD/deps/build
if [[ "$1" == "" ]]; then
    echo "No install directory provided, falling back to: $DEPS_BUILD"
else
    DEPS_BUILD=$1
fi

DEPS_CMAKE_DEPO=$DEPS_BUILD/lib/cmake
mkdir -p $DEPS_BUILD
mkdir -p $DEPS_CMAKE_DEPO

# if possible, ask for the precise number of processors,
# otherwise take 2 processors as reasonable default; see
# https://docs.travis-ci.com/user/speeding-up-the-build/#Makefile-optimization
if [ -x /usr/bin/getconf ]; then
    NPROCESSORS=$(/usr/bin/getconf _NPROCESSORS_ONLN)
else
    NPROCESSORS=2
fi

# Tell make to use the processors. No preceding '-' required.
MAKEFLAGS="j${NPROCESSORS}"
export MAKEFLAGS


for dep in ${!depList[@]}; do
if [[ -e deps/$dep ]]; then
    echo "Existing $dep directory, no need to clone"
else
    git clone ${depList[$dep]} deps/$dep || exit 1
fi
done

for dep in ${!depList[@]}; do
    mkdir -p deps/$dep/build

    pushd deps/$dep || exit 1

    git pull

    if [[ -e buildDeps.sh ]]; then
        ./buildDeps.sh $DEPS_FLAGS $DEPS_BUILD || exit 1
    fi


    if [[ $doBuild == true ]]; then
        pushd build || exit 1

        cmake -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH:PATH=$DEPS_CMAKE_DEPO" "-DCMAKE_INSTALL_PREFIX:PATH=$DEPS_BUILD" .. || exit 1
        make -j 3 || exit 1
        make install || exit 1

        popd || exit 1
    fi

    popd || exit 1
done
