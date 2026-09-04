import test from 'node:test'; import assert from 'node:assert/strict'; import { findScheduleConflicts } from '../lib/scheduling/conflicts';
const base={post_id:'g2',shift_id:'morning',duty_date:'2026-09-04',status:'DRAFT' as const};
test('reports duplicate employee assignments',()=>{const result=findScheduleConflicts([{...base,id:'1',employee_id:'e1'},{...base,id:'2',employee_id:'e1'}],[]);assert.equal(result[0].code,'DUPLICATE_EMPLOYEE');});
test('reports uncovered required posts',()=>{const result=findScheduleConflicts([{...base,id:'1',employee_id:'e1'}],['g1:morning']);assert.equal(result[0].code,'UNCOVERED_POST');});
test('reports assignment away from a configured pinned duty',()=>{const result=findScheduleConflicts([{...base,id:'1',employee_id:'garcia',post_id:'g3'}],[],{employeeId:'garcia',postId:'g2',shiftId:'morning'});assert.equal(result[0].code,'PINNED_ASSIGNMENT');});
