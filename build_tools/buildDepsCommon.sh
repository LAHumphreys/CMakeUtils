if [[ "$DEPS_ROOT" == "" ]]; then
    DEPS_ROOT=$PWD/deps
    echo "No deps directory (DEPS_ROOT) provided, falling back to: $DEPS_ROOT"
fi
DEPS_BUILD=$DEPS_ROOT/build
export DEPS_BUILD

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

for dep in ${!bzipList[@]}; do
if [[ -e $DEPS_ROOT/$dep ]]; then
    echo "Existing $dep directory, no need to get"
else
    pushd $DEPS_ROOT
    mkdir $dep
    pushd $dep
    wget ${bzipList[$dep]} || exit 1
    bunzip2 *.bz2
    tar -xvf *.tar
    rm *.tar
    popd
    popd
fi
done

for dep in ${!depList[@]}; do
if [[ -e $DEPS_ROOT/$dep ]]; then
    echo "Existing $dep directory, no need to clone"
else
    git clone ${depList[$dep]} $DEPS_ROOT/$dep || exit 1
fi
done

for dep in ${!depList[@]}; do
    mkdir -p $DEPS_ROOT/$dep/build

    pushd $DEPS_ROOT/$dep || exit 1

    git pull

    if [[ -e buildDeps.sh ]]; then
        ./buildDeps.sh $DEPS_ROOT || exit 1
    fi

    # CMake project?
    if [[ -e CMakeLists.txt ]]; then
        pushd build || exit 1

        cmake -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH:PATH=$DEPS_CMAKE_DEPO" "-DCMAKE_INSTALL_PREFIX:PATH=$DEPS_BUILD" .. || exit 1
        make -j 3 || exit 1
        make install || exit 1

        popd || exit 1
    elif [[ -e Makefile ]]; then
        DEPS_ROOT=$DEPS_ROOT make -j 3 || exit 1
        INSTALL_PREFIX=$DEPS_BUILD DEPS_ROOT=$DEPS_ROOT make install || exit 1
    fi


    popd || exit 1
done
