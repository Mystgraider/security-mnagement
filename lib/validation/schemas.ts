import { z } from 'zod';
export const departmentSchema=z.object({name:z.string().trim().min(2).max(120),code:z.string().trim().toUpperCase().regex(/^[A-Z0-9_-]+$/)});
export const scheduleSchema=z.object({employee_id:z.string().uuid(),post_id:z.string().uuid(),shift_id:z.string().uuid(),duty_date:z.string().date(),status:z.enum(['DRAFT','PUBLISHED','ARCHIVED'])});
export const leaveRequestSchema=z.object({employee_id:z.string().uuid(),start_date:z.string().date(),end_date:z.string().date(),reason:z.string().trim().min(1).max(1000)}).refine(v=>v.end_date>=v.start_date,{message:'End date must not precede start date',path:['end_date']});
