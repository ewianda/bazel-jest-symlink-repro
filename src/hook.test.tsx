import { renderHook } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import React from 'react'
import { useDeleteItem } from './hook'

describe('useDeleteItem', () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  it('should delete an item', async () => {
    const { result } = renderHook(() => useDeleteItem(), { wrapper })

    await result.current.mutateAsync('123')

    expect(result.current.isSuccess).toBe(true)
  })
})
