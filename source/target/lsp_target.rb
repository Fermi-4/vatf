require 'build_client'
require 'boot'
require '../Boot/bootscript'
require 'target/lsp_target_controller'
require '../TestPlans/LSP/lsp_constants'
require '../TestPlans/LSP/default_test_module'
require '../TestPlans/LSP/default_perf_module'
require '../TestPlans/LSP/default_fs_api_module'

include LspTargetHandlers
