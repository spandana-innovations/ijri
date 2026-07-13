declare module "mammoth/mammoth.browser" {
  export interface MammothImage { contentType: string; read(encoding: string): Promise<string>; }
  export interface ConvertResult { value: string; messages: unknown[]; }
  export const images: { imgElement(fn: (image: MammothImage) => Promise<{ src: string }>): unknown };
  export function convertToHtml(input: { arrayBuffer: ArrayBuffer }, options?: unknown): Promise<ConvertResult>;
  const _default: { convertToHtml: typeof convertToHtml; images: typeof images };
  export default _default;
}
declare module "mammoth" {
  export * from "mammoth/mammoth.browser";
  import d from "mammoth/mammoth.browser";
  export default d;
}
