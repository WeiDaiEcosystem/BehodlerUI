import { BaseContract } from '../BaseContract';
import { /*address,*/ uint } from '../SolidityTypes'

export default interface Migrator extends BaseContract {
    stepCounter: () => any
    bridge: () => any
    initBridge: () => any
    bail: () => any
    step1: () => any
    step2: (tokens: string[]) => any
    step3: () => any
    step4: (iterations: uint) => any
    step5: (iterations: uint) => any
    step6: (iterations: uint) => any
    step7: () => any
}