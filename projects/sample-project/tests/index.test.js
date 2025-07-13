// Sample Project Tests - TDD デモンストレーション

const { main, add } = require('../src/index');

describe('Sample Project', () => {
    describe('main function', () => {
        test('should return success status', () => {
            const result = main();
            
            expect(result.status).toBe('success');
            expect(result.message).toBe('Demo completed');
            expect(result.timestamp).toBeDefined();
        });
        
        test('should return ISO timestamp', () => {
            const result = main();
            const timestamp = new Date(result.timestamp);
            
            expect(timestamp).toBeInstanceOf(Date);
            expect(timestamp.toISOString()).toBe(result.timestamp);
        });
    });
    
    describe('add function', () => {
        test('should add two positive numbers', () => {
            expect(add(2, 3)).toBe(5);
            expect(add(10, 15)).toBe(25);
        });
        
        test('should add negative numbers', () => {
            expect(add(-2, -3)).toBe(-5);
            expect(add(-10, 5)).toBe(-5);
        });
        
        test('should handle zero', () => {
            expect(add(0, 0)).toBe(0);
            expect(add(5, 0)).toBe(5);
            expect(add(0, -3)).toBe(-3);
        });
        
        test('should throw error for non-number inputs', () => {
            expect(() => add('2', 3)).toThrow('Both arguments must be numbers');
            expect(() => add(2, '3')).toThrow('Both arguments must be numbers');
            expect(() => add(null, undefined)).toThrow('Both arguments must be numbers');
        });
    });
});