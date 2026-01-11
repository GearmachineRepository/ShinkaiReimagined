--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local EnsembleTypes = require(Shared.Types.EnsembleTypes)

export type EventBus = EnsembleTypes.EventBus
export type Connection = EnsembleTypes.Connection

export type ExecutionEntity = {
	Character: Model,
	Humanoid: Humanoid,
	IsPlayer: boolean,
	Player: Player?,
}

export type Block = {
	BlockType: string,
	BlockId: string?,
	RequireSignal: (string | { string })?,
	RequireAll: boolean?,
	[string]: any,
}

export type WaitBlock = Block & {
	Time: number?,
}

export type AnimationBlock = Block & {
	AnimationId: string,
	Speed: number?,
	Loop: boolean?,
	Priority: Enum.AnimationPriority?,
}

export type SoundBlock = Block & {
	SoundId: string,
	Volume: number?,
	Speed: number?,
}

export type VelocityBlock = Block & {
	X: number?,
	Y: number?,
	Z: number?,
	Time: number?,
	Fade: boolean?,
	Track: boolean?,
}

export type HitboxBlock = Block & {
	X: number?,
	Y: number?,
	Z: number?,
	SizeX: number?,
	SizeY: number?,
	SizeZ: number?,
	Stun: number?,
	Damage: number?,
	AttackType: string?,
	Blockable: boolean?,
	Block360: boolean?,
	CancelEnemy: boolean?,
	Outputs: {
		OnHit: string?,
		OnMiss: string?,
		Duration: number?,
	}?,
}

export type HitCancelBlock = Block & {
	Time: number?,
	Flip: boolean?,
	Endlag: number?,
	Branch: string?,
}

export type ActionBlock = Block & {
	ActionId: string,
	Speed: number?,
	CancelLast: boolean?,
	HoldFor: number?,
}

export type SignalBlock = Block & {
	SignalId: string,
	Duration: number?,
	Clear: boolean?,
}

export type AndGateBlock = Block & {
	Inputs: { string },
	Threshold: number?,
	Output: string?,
	Duration: number?,
}

export type OrGateBlock = Block & {
	Inputs: { string },
	Output: string?,
	Duration: number?,
}

export type NotGateBlock = Block & {
	Input: string,
	Output: string?,
	Duration: number?,
}

export type TimerBlock = Block & {
	Input: string?,
	Time: number,
	Output: string?,
	OutputDuration: number?,
}

export type CounterBlock = Block & {
	Input: string?,
	Threshold: number,
	Output: string?,
	Duration: number?,
	ResetOnThreshold: boolean?,
}

export type AddHealthBlock = Block & {
	Amount: number?,
}

export type ActionConditions = {
	OnAir: boolean?,
	HasTarget: boolean?,
	Durability: number?,
}

export type ActionProperties = {
	DamageMultiplier: number?,
	KnockbackMultiplier: number?,
	Invincible: boolean?,
}

export type Branch = {
	Entry: boolean?,
	Timeline: { Block },
}

export type ActionDefinition = {
	ActionId: string,
	DisplayName: string?,
	Timeline: { Block }?,
	Branches: { [string]: Branch }?,
	Conditions: ActionConditions?,
	Properties: ActionProperties?,
}

export type ToolDefinition = {
	ToolId: string,
	DisplayName: string,
	Icon: string,
	DefaultSlot: number,
	Cooldown: number,
	ActionId: string,
	GroundOnly: boolean?,
	RequiresTarget: boolean?,
}

export type HitRecord = {
	Target: Model,
	Timestamp: number,
	Damage: number,
}

export type SignalState = {
	Active: { [string]: boolean },
	Expiry: { [string]: number },
	Counters: { [string]: number },
}

export type ExecutionContext = {
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: EventBus,
	StartTime: number,
	Canceled: boolean,
	Properties: ActionProperties,
	HitRecords: { HitRecord },
	LastHitTarget: Model?,
	Signals: SignalState,

	GetElapsedTime: () -> number,
	Cancel: () -> (),
	RecordHit: (Target: Model, Damage: number) -> (),
	HadHitInWindow: (WindowSeconds: number) -> boolean,
	GetLastHitTarget: () -> Model?,

	EmitSignal: (SignalId: string, Duration: number?) -> (),
	ClearSignal: (SignalId: string) -> (),
	IsSignalActive: (SignalId: string) -> boolean,
	GetActiveSignals: () -> { string },
	IncrementCounter: (CounterId: string) -> number,
	GetCounter: (CounterId: string) -> number,
	ResetCounter: (CounterId: string) -> (),
}

export type HandlerResult = {
	JumpToBranch: string?,
	Cancel: boolean?,
}

export type BlockHandler = {
	Execute: (Block: Block, Context: ExecutionContext) -> HandlerResult?,
}

export type HitData = {
	Attacker: ExecutionEntity,
	Target: Model,
	Damage: number,
	Stun: number?,
	AttackType: string?,
	Blockable: boolean?,
	Block360: boolean?,
	CancelEnemy: boolean?,
	Position: Vector3,
}

return nil