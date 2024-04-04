export type TIP = [number, number, number, number];
export default class domain {
    readonly __domain: string;
    constructor(__domain: string);
    get domain(): string;
    protected set(ip: TIP): boolean;
    protected register(ip: TIP): boolean;
    protected update(ip: TIP): boolean;
    protected exists(): boolean;
}
