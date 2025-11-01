import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'My Tiny App - Item Management',
  description: 'CRUD operations for Item Management',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

