import type { DutySchedule } from '@/types/database';
export type Conflict={code:'DUPLICATE_EMPLOYEE'|'UNCOVERED_POST'|'PINNED_ASSIGNMENT';message:string};
export type PinnedAssignment={employeeId:string;postId:string;shiftId:string};
/** Validates only supplied/configured rules; it never generates or rotates schedules. */
export function findScheduleConflicts(rows:DutySchedule[], requiredPostShiftKeys:string[], pinned?:PinnedAssignment):Conflict[] {
 const seen=new Set<string>(); const assigned=new Set<string>(); const conflicts:Conflict[]=[];
 for(const r of rows){const employeeKey=`${r.employee_id}:${r.duty_date}`; if(seen.has(employeeKey)) conflicts.push({code:'DUPLICATE_EMPLOYEE',message:'An employee cannot have more than one duty on the same date.'}); seen.add(employeeKey); assigned.add(`${r.post_id}:${r.shift_id}`);}
 for(const required of requiredPostShiftKeys) if(!assigned.has(required)) conflicts.push({code:'UNCOVERED_POST',message:'A required post has no assignment.'});
 if(pinned && rows.some(r=>r.employee_id===pinned.employeeId && (r.post_id!==pinned.postId || r.shift_id!==pinned.shiftId))) conflicts.push({code:'PINNED_ASSIGNMENT',message:'The employee has a configured pinned assignment; use an approved replacement when unavailable.'});
 return conflicts;
}
