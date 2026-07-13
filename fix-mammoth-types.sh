#!/usr/bin/env bash
# ==========================================================================
# IJRI — fix: mammoth's browser build has no bundled type declarations, so
# `import("mammoth/mammoth.browser")` fails type-checking under strict mode.
# Add an ambient module declaration (picked up via tsconfig "**/*.ts").
# Run in repo:  bash fix-mammoth-types.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Adding mammoth type declaration..."
mkdir -p src/types

cat > src/types/mammoth.d.ts << 'IJRI_EOF'
// mammoth ships no types for its browser entry point.
declare module "mammoth/mammoth.browser" {
  const mammoth: any;
  export default mammoth;
}
declare module "mammoth" {
  const mammoth: any;
  export default mammoth;
}
IJRI_EOF

echo "Wrote src/types/mammoth.d.ts"
echo "Now run:  npm run build"
