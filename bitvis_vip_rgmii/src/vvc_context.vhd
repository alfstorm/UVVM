--================================================================================================================================
-- Copyright 2020 Bitvis and Inventas AS
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and in the provided LICENSE.TXT.
--
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
-- an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and limitations under the License.
--================================================================================================================================
-- Note : Any functionality not explicitly described in the documentation is subject to change at any time
----------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- Description : See library quick reference (under 'doc') and README-file(s)
---------------------------------------------------------------------------------------------

context vvc_context is
  library bitvis_vip_rgmii;
  use bitvis_vip_rgmii.transaction_pkg.all;
  use bitvis_vip_rgmii.vvc_methods_pkg.all;
  use bitvis_vip_rgmii.td_vvc_framework_common_methods_pkg.all;
  use bitvis_vip_rgmii.rgmii_bfm_pkg.t_rgmii_tx_if;
  use bitvis_vip_rgmii.rgmii_bfm_pkg.t_rgmii_rx_if;
  use bitvis_vip_rgmii.rgmii_bfm_pkg.t_rgmii_bfm_config;
  use bitvis_vip_rgmii.rgmii_bfm_pkg.C_RGMII_BFM_CONFIG_DEFAULT;
end context;
