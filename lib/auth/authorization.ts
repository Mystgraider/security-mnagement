import type { Role } from '@/types/database';
const adminRoles: Role[]=['SUPER_ADMIN','MANAGEMENT','SECURITY_MANAGER','HR'];
export const canManageDirectory=(role:Role)=>adminRoles.includes(role);
export const canPublishSchedule=(role:Role)=>['SUPER_ADMIN','SECURITY_MANAGER'].includes(role);
export const canAssignRole=(actor:Role, proposed:Role)=> actor==='SUPER_ADMIN' && proposed !== 'SUPER_ADMIN';
