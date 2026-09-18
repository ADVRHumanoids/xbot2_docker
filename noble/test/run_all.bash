SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

set -e

# Run all tests
TEST_CASE=test_ldd.bash
echo ">>> Running test: $TEST_CASE"
bash "$SCRIPT_DIR/$TEST_CASE"
echo "<<< Test $TEST_CASE passed"

echo "All tests passed"