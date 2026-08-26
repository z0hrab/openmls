-- Replace the single registration record of an emulation group with a log of
-- the derivation epochs it registered. Every logged epoch keeps its per-epoch
-- state alive, so the log is what bounds how long that state is retained.
--
-- The old record and the new log are serialized by the application's codec, so
-- SQL cannot turn one into the other. The old table is dropped rather than
-- migrated: a group whose log is gone is no longer recognized as an emulation
-- group and has to be rejoined. Virtual clients are an unreleased draft
-- feature, so no deployed state is at stake.
DROP TABLE registered_vc_derivation_epochs;

CREATE TABLE vc_derivation_epoch_logs (
    provider_version INTEGER NOT NULL,
    group_id BLOB NOT NULL,
    log BLOB NOT NULL,
    PRIMARY KEY (group_id)
);

-- Projection of the log onto the derivation epochs it names. One row per
-- (emulation group, derivation epoch) pair, rewritten whole whenever the
-- group's log is written. The log itself is an opaque blob, so this table is
-- what lets the guarded delete of a derivation epoch's state find the groups
-- that still have it logged and keep the state alive for them.
CREATE TABLE vc_derivation_epoch_log_epochs (
    provider_version INTEGER NOT NULL,
    group_id BLOB NOT NULL,
    epoch_id BLOB NOT NULL,
    PRIMARY KEY (group_id, epoch_id)
);

-- The guarded delete queries by epoch alone, which the group-first primary key
-- cannot serve.
CREATE INDEX vc_derivation_epoch_log_epochs_epoch_id
    ON vc_derivation_epoch_log_epochs (epoch_id);
