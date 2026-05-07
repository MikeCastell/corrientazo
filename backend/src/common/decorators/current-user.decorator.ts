import { createParamDecorator, ExecutionContext } from "@nestjs/common";

export type CurrentUser = { userId: string; role: string };

export const CurrentUserDecorator = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): CurrentUser => {
    const request = ctx.switchToHttp().getRequest();
    return request.user as CurrentUser;
  }
);

