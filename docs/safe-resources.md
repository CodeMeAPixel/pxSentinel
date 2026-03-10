# Safe Resources

`shared/allowed.lua` defines `Config.SafeResources` — a list of resource folder names that pxSentinel will never scan. Any resource on this list is skipped entirely without reading any of its files.

---

## Why an Allow List Exists

Some legitimate resources contain strings that overlap with malware signatures. For example, a security auditing tool might reference `luraph` or `ironbrew` in its own signature list. Scanning well-known, trusted platform resources also has no value and adds unnecessary startup time.

The allow list is the mechanism to exclude resources from scanning without disabling pxSentinel entirely.

---

## Default Entries

The default list covers the following categories:

### CFx / Cfx.re platform resources

Core resources provided by the FiveM platform itself:

```
chat, spawnmanager, mapmanager, sessionmanager,
hardcap, baseevents, basic-gamemode,
fivem-map-hipster, fivem-map-skater
```

### txAdmin / monitor

```
monitor, txAdmin
```

### Build system resources

```
webpack, yarn
```

### ox stack

```
ox_lib, ox_inventory, ox_target, ox_fuel,
ox_doorlock, ox_banking, ox_vehicledealer
```

### QBCore

```
qb-core, qb-inventory, qb-hud, qb-policejob,
qb-ambulancejob, qb-garages, qb-phone, qb-vehicleshop,
qb-menu, qb-target, qb-clothing, qb-banking, qb-multicharacter
```

### ESX

```
es_extended, esx_menu_default, esx_menu_dialog, esx_menu_list,
esx_identity, esx_skin, esx_vehicleshop, esx_banking,
esx_policejob, esx_ambulancejob, esx_society
```

### Common trusted standalone resources

```
screenshot-basic, oxmysql, mysql-async, ghmattimysql,
pma-voice, saltychat, mumble-voip, evidence-camera
```

### CodeMeAPixel resources

```
pxSentinel, pxLoadingScreen, pxMechanic, [pixel]
```

---

## Adding Resources

Add entries at the bottom of `shared/allowed.lua` using the exact resource folder name:

```lua
Config.SafeResources = {
    -- existing entries ...

    -- my trusted resources
    'my-framework',
    'my-hud',
}
```

> **Use the exact folder name.** The folder name is the string that appears after `start` or `ensure` in `server.cfg` and is the name of the directory inside `resources/`. Wildcards and partial matches are not supported.

---

## pxSentinel Itself

pxSentinel's own resource name (`pxSentinel`) is always excluded from scanning by the `isSafe()` function, regardless of whether it appears in `Config.SafeResources`. Removing it from the list has no effect.

---

## Caution

The allow list should be kept as small as practical. Adding a resource to this list means its server-side files are **never inspected**, even if they are later modified to contain malicious content. Only add resources you genuinely trust and that you maintain direct control over, or that are sourced from verified official repositories.

Avoid adding entire framework wrappers or large script collections as single entries. If a framework is broken into individually named resources, list only the specific entries that cause false positives.
