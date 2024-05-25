git submodule deinit -f lib/flax
git rm -f lib/flax
rm -rf .git/modules/lib/flax

git submodule deinit -f lib/v2-core
git rm -f lib/v2-core
rm -rf .git/modules/lib/v2-core
rm -rf lib/flax
rm -rf lib/v2-core
forge clean
forge update
