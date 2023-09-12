--------------------------------------------------
-- Dumpster                                     --
--------------------------------------------------

export type Dumpster = {
	new: () -> Dumpster,
	Add: (self: Dumpster, object: any, cleanUpIdentifier: string?, customCleanupMethod: string?) -> any?,
	Extend: (self: Dumpster) -> Dumpster,
	Construct: (self: Dumpster, base: (string | {} | () -> ()), ...any) -> any?,
	Clone: (self: Dumpster, item: Instance) -> Instance,
	BindToRenderStep: (self: Dumpster, name: string, priority: number, callback: (deltaTime: number) -> (any)) -> (),
	UnbindFromRenderStep: (self: Dumpster, name: string) -> (),
	Connect: (self: Dumpster, signal: RBXScriptSignal, callback: (...any) -> ()) -> any?,
	AttachTo: (self: Dumpster, item: Instance) -> (),
	Remove: (self: Dumpster, objectToRemove: any, skipCleaning: boolean?) -> any?,
	Clean: (self: Dumpster) -> boolean,
	Destroy: (self: Dumpster) -> ()
}

--------------------------------------------------
-- Replicas                                     --
--------------------------------------------------
export type ReplicaClient = {
    Data: {},
    Id: number,
    Class: string,
    Tags: {},
    Parent: ReplicaClient,
    Children: {},
    IsActive: (ReplicaClient) -> boolean,
    Identify: (ReplicaClient) -> string,
    AddCleanupTask: (ReplicaClient) -> () | Instance,
    RemoveCleanupTask: (ReplicaClient) -> () | Instance,
	ListenToWrite: (ReplicaClient, string, (...any) -> ()) -> (RBXScriptConnection),
	ListenToChange: (ReplicaClient, path: string | {string}, listener: (...any) -> ()) -> (RBXScriptConnection),
	ListenToNewKey: (ReplicaClient, path: string | {string}, listener: (...any) -> ()) -> (RBXScriptConnection),
	ListenToArrayInsert: (ReplicaClient, path: string | {string}, listener: (...any) -> ()) -> (RBXScriptConnection),
	ListenToArraySet: (ReplicaClient, path: string | {string}, listener: (...any) -> ()) -> (RBXScriptConnection),
	ListenToArrayRemove: (ReplicaClient, path: string | {string}, listener: (...any) -> ()) -> (RBXScriptConnection),
	ListenToRaw: (ReplicaClient, callback: (...any) -> ()) -> (RBXScriptConnection),
	ListenToChildAdded: (ReplicaClient, callback: (...any) -> ()) -> (RBXScriptConnection),
	FindFirstChildOfClass: (ReplicaClient, ClassName: string) -> (ReplicaClient?),
	ConnectOnClientEvent: (ReplicaClient, callback: (...any) -> ()) -> (RBXScriptConnection),
	FireServer: (ReplicaClient, ...any) -> (),
}

export type ReplicaServer = {
    Data: {},
    Id: number,
    Class: string,
    Tags: {},
    Parent: ReplicaServer,
    Children: {},
    IsActive: (ReplicaServer) -> boolean,
    Identify: (ReplicaServer) -> string,
    AddCleanupTask: (ReplicaServer) -> () | Instance,
    RemoveCleanupTask: (ReplicaServer) -> () | Instance,
    SetValue: (ReplicaServer, path: string | {string}, newValue: any?) -> (),
    SetValues: (ReplicaServer, path: string | {string}, ...any) -> (),
    ArrayInsert: (ReplicaServer, path: string | {string}, newValue: any) -> (number),
    ArraySet: (ReplicaServer, path: string | {string}, index: number, newValue: any) -> (),
    ArrayRemove: (ReplicaServer, path: string | {string}, index: number) -> (any),
    Write: (ReplicaServer, string, ...any) -> (...any),
    SetParent: (ReplicaServer, parent: ReplicaServer) -> (),
    ReplicateFor: (ReplicaServer, "All" | Player) -> (),
    DestroyFor: (ReplicaServer, "All" | Player) -> (),
    ConnectOnServerEvent: (ReplicaServer, Player, ...any) -> (RBXScriptConnection),
    FireClient: (ReplicaServer, Player, ...any) -> (),
    FireAllClients: (ReplicaServer, Player, ...any) -> (),
    Destroy: (ReplicaServer) -> (),
}

--------------------------------------------------
-- sleitnick's Signal.lua                       --
--------------------------------------------------
export type SignalModule = { new: () -> Signal<T...> }
export type SignalConnection = {
	Disconnect: (self: SignalConnection) -> (),
	Destroy: (self: SignalConnection) -> (),
	Connected: boolean,
}
export type Signal<T...> = {
	Fire: (self: Signal<T...>, ...any) -> (),
	FireDeferred: (self: Signal<T...>, ...any) -> (),
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> SignalConnection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> SignalConnection,
	DisconnectAll: (self: Signal<T...>) -> (),
	GetConnections: (self: Signal<T...>) -> { SignalConnection },
	Destroy: (self: Signal<T...>) -> (),
	Wait: (self: Signal<T...>) -> T...,
}

--------------------------------------------------
-- roblox-lua-promise                           --
--------------------------------------------------
type PromiseResolve<T...> = (T...) -> (T...)

type PromiseReject = (errorMessage: string?) -> ()

type PromiseOnCancel = (abortHandler: (() -> ())?) -> boolean

type PromiseExecutor<T...> = (resolve: PromiseResolve<T...>, reject: PromiseReject, onCancel: PromiseOnCancel) -> ()

export type PromiseModule = {
	all: ({ Promise<T...> }) -> Promise<T...>,
	allSettled: ({ Promise<T...> }) -> Promise<T...>,
	any: ({ Promise<T...> }) -> Promise<T...>,
	async: (executor: PromiseExecutor<T...>) -> Promise<T...>,
	defer: (executor: PromiseExecutor<T...>) -> Promise<T...>,
	delay: (timeToDelay: number) -> Promise<T...>,
	each: ({ Promise<T...> }) -> Promise<T...>,
	fromEvent: (RBXScriptSignal, executor: PromiseExecutor<T...>) -> Promise<T...>,
	is: (obj: any?) -> boolean,
	new: (executor: PromiseExecutor<T...>) -> Promise<T...>,
	promisify: (callback: (...any) -> (...any)) -> Promise<T...>,
	prototype: (executor: PromiseExecutor<T...>) -> Promise<T...>,
	race: ({ Promise<T...> }) -> Promise<T...>,
	reject: (value: any?) -> Promise<T...>,
	resolve: (value: any) -> Promise<T...>,
	retry: (prom: Promise<T...>, maxTimes: number, delayBetween: number) -> Promise<T...>,
	some: ({ Promise<T...> }) -> Promise<T...>,
	try: (executor: PromiseExecutor<T...>) -> Promise<T...>,
}

export type Promise<T...> = {
	andThen: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> Promise<T...>,
	andThenCall: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> Promise<T...>,
	andThenReturn: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> any,
	await: (self: Promise<T...>) -> (),
	awaitStatus: (self: Promise<T...>) -> (),
	awaitValue: (self: Promise<T...>) -> Promise<T...>,
	cancel: (self: Promise<T...>) -> (),
	catch: (self: Promise<T...>, func: (e: string?) -> ()) -> Promise<T...>,
	done: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> Promise<T...>,
	doneCall: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> Promise<T...>,
	doneReturn: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> (),
	expect: (self: Promise<T...>) -> (),
	finally: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> Promise<T...>,
	finallyCall: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> Promise<T...>,
	finallyReturn: (self: Promise<T...>, executor: PromiseExecutor<T...>) -> (),
	getStatus: (self: Promise<T...>) -> any,
	now: (self: Promise<T...>) -> (),
	tap: (self: Promise<T...>) -> Promise<T...>,
	timeout: (secs: any) -> Promise<T...>,
}

return nil
