import Cloudflare from 'cloudflare';

export type TIP = [number, number, number, number];

export default class domain {
  constructor(
    readonly __domain: string
  ) {

  }

  get domain(): string {
    return this.__domain;
  }

  protected set(ip: TIP): boolean {
    return false;
  }

  protected register(ip: TIP): boolean {
    return false;
  }

  protected update(ip: TIP): boolean {
    return false;
  }

  protected exists(): boolean {
    return false;
  }
}