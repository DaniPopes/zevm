const std = @import("std");
const evmc = @import("evmc");

/// EVM revision.
///
/// The revision of the EVM specification based on the Ethereum
/// upgrade / hard fork codenames.
pub const Rev = enum(evmc.enum_evmc_revision) {
    /// The Frontier revision.
    ///
    /// The one Ethereum launched with.
    frontier = evmc.EVMC_FRONTIER,

    /// The Homestead revision.
    ///
    /// https://eips.ethereum.org/EIPS/eip-606
    homestead = evmc.EVMC_HOMESTEAD,

    /// The Tangerine Whistle revision.
    ///
    /// https://eips.ethereum.org/EIPS/eip-608
    tangerine_whistle = evmc.EVMC_TANGERINE_WHISTLE,

    /// The Spurious Dragon revision.
    ///
    /// https://eips.ethereum.org/EIPS/eip-607
    spurious_dragon = evmc.EVMC_SPURIOUS_DRAGON,

    /// The Byzantium revision.
    ///
    /// https://eips.ethereum.org/EIPS/eip-609
    byzantium = evmc.EVMC_BYZANTIUM,

    /// The Constantinople revision.
    ///
    /// https://eips.ethereum.org/EIPS/eip-1013
    constantinople = evmc.EVMC_CONSTANTINOPLE,

    /// The Petersburg revision.
    ///
    /// Other names: Constantinople2, ConstantinopleFix.
    ///
    /// https://eips.ethereum.org/EIPS/eip-1716
    petersburg = evmc.EVMC_PETERSBURG,

    /// The Istanbul revision.
    ///
    /// https://eips.ethereum.org/EIPS/eip-1679
    istanbul = evmc.EVMC_ISTANBUL,

    /// The Berlin revision.
    ///
    /// https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/berlin.md
    berlin = evmc.EVMC_BERLIN,

    /// The London revision.
    ///
    /// https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/london.md
    london = evmc.EVMC_LONDON,

    /// The Paris revision (aka The Merge).
    ///
    /// https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/paris.md
    paris = evmc.EVMC_PARIS,

    /// The Shanghai revision.
    ///
    /// https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/shanghai.md
    shanghai = evmc.EVMC_SHANGHAI,

    /// The Cancun revision.
    ///
    /// https://github.com/ethereum/execution-specs/blob/master/network-upgrades/mainnet-upgrades/cancun.md
    cancun = evmc.EVMC_CANCUN,

    /// The Prague revision.
    ///
    /// The future next revision after Cancun.
    prague = evmc.EVMC_PRAGUE,

    /// The Osaka revision.
    ///
    /// The future next revision after Prague.
    osaka = evmc.EVMC_OSAKA,

    /// The maximum EVM revision supported.
    pub const max = @as(Rev, @enumFromInt(evmc.EVMC_MAX_REVISION));

    /// The latest known EVM revision with finalized specification.
    ///
    /// This is handy for EVM tools to always use the latest revision available.
    pub const latest = @as(Rev, @enumFromInt(evmc.EVMC_LATEST_STABLE_REVISION));

    /// Returns `true` if the given revision is enabled in this revision.
    pub inline fn enabled(self: Rev, other: Rev) bool {
        return @intFromEnum(self) >= @intFromEnum(other);
    }
};
