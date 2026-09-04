import './globals.css';
import type { Metadata } from 'next';
export const metadata: Metadata = { title: 'HotelSecOps', description: 'Hotel safety and security operations' };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="en"><body>{children}</body></html>; }
