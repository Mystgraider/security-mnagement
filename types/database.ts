export type Role = 'SUPER_ADMIN'|'MANAGEMENT'|'SECURITY_MANAGER'|'SECURITY_OFFICER'|'SECURITY_SUPERVISOR'|'SECURITY_GUARD'|'DEPARTMENT_HEAD'|'HR'|'VIEWER';
export type ScheduleStatus = 'DRAFT'|'PUBLISHED'|'ARCHIVED';
export type DutySchedule = { id:string; employee_id:string; post_id:string; shift_id:string; duty_date:string; status:ScheduleStatus; };
