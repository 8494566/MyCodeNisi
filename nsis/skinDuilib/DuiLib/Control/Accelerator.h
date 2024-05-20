/**
* Copyright (C) 2014-2050 
* All rights reserved.
* 
* @file       Accelerator.h
* @brief      
* @version    v1.0      
* @author     SOUI group   
* @date       2014/08/02
* 
* Describe    SOUI���ټ�����ģ��
*/

#pragma once

namespace DuiLib
{
	typedef CDuiString SStringT;

	template< typename T >
	class CElementTraitsBase
	{
	public:
		typedef const T& INARGTYPE;
		typedef T& OUTARGTYPE;

		static void CopyElements( T* pDest, const T* pSrc, size_t nElements )
		{
			for( size_t iElement = 0; iElement < nElements; iElement++ )
			{
				pDest[iElement] = pSrc[iElement];
			}
		}

		static void RelocateElements( T* pDest, T* pSrc, size_t nElements )
		{
			// A simple memmove works for nearly all types.
			// You'll have to override this for types that have pointers to their
			// own members.
			memmove_s( pDest, nElements*sizeof( T ), pSrc, nElements*sizeof( T ));
		}
	};

	template< typename T >
	class CDefaultHashTraits
	{
	public:
		static ULONG Hash( const T& element )
		{
			return( ULONG( ULONG_PTR( element ) ) );
		}
	};

	template< typename T >
	class CDefaultCompareTraits
	{
	public:
		static bool CompareElements( const T& element1, const T& element2 )
		{
			return( (element1 == element2) != 0 );  // != 0 to handle overloads of operator== that return BOOL instead of bool
		}

		static int CompareElementsOrdered( const T& element1, const T& element2 )
		{
			if( element1 < element2 )
			{
				return( -1 );
			}
			else if( element1 == element2 )
			{
				return( 0 );
			}
			else
			{
				//SASSERT( element1 > element2 );
				return( 1 );
			}
		}
	};

	template< typename T >
	class CDefaultElementTraits :
		public CElementTraitsBase< T >,
		public CDefaultHashTraits< T >,
		public CDefaultCompareTraits< T >
	{
	};

	template< typename T >
	class CElementTraits :
		public CDefaultElementTraits< T >
	{
	};

    /**
    * @class      CAccelerator
    * @brief      ���ټ�ӳ��
    * 
    * Describe
    */
    class CAccelerator
    {
    public:

        /**
         * CAccelerator
         * @brief    ���캯��
         * @param    DWORD dwAccel --  ���ټ�ֵ
         * Describe  
         */    
        CAccelerator(DWORD dwAccel);

        /**
         * CAccelerator
         * @brief    ���캯��
         * @param    UINT vKey --  ��ֵ
         * @param    bool bCtrl --  ��Ctrl���
         * @param    bool bAlt --  ��Alt���
         * @param    bool bShift --  ��Shilft���
         * Describe  
         */    
        CAccelerator(UINT vKey=0,bool bCtrl=false,bool bAlt=false,bool bShift=false);

        /**
         * ~CAccelerator
         * @brief    ��������
         * Describe  
         */    
        ~CAccelerator(void);

        /**
         * GetKeyName
         * @brief    ������ֵת��Ϊ��Ӧ���ַ���
         * @param    WORD vk --  ����ֵ
         * @return   SOUI::SStringT -- ����
         * Describe  
         */    
        SStringT GetKeyName(WORD vk);

        /**
         * FormatHotkey
         * @brief    ��õ�ǰ���ټ����ַ�����ʽ
         * @return   SOUI::SStringT -- ���ټ����ַ�����ʽ
         * Describe  
         */    
        SStringT FormatHotkey();

        /**
         * GetModifier
         * @brief    ��ü��ټ�������λ
         * @return   WORD -- ���ټ������μ�
         * Describe  
         */    
        WORD GetModifier() const {return m_wModifier;}

        /**
         * GetKey
         * @brief    ��ü��ټ�������
         * @return   WORD -- ���ټ�������
         * Describe  
         */    
        WORD GetKey() const {return m_wVK;}

        /**
         * TranslateAccelKey
         * @brief    �������ַ�����Ӧ�ļ��ټ�ֵ
         * @param    LPCTSTR pszKeyName --  ������ټ����ַ���
         * @return   DWORD -- ���ټ�ֵ
         * Describe  
         */    
        static DWORD TranslateAccelKey(LPCTSTR pszKeyName);
    protected:
        WORD     m_wModifier;
        WORD    m_wVK;
    };

    template<>
    class  DuiLib::CElementTraits< DuiLib::CAccelerator > : public DuiLib::CElementTraitsBase< DuiLib::CAccelerator >
    {
    public:
        static ULONG Hash(INARGTYPE element ) throw()
        {
            return MAKELONG(element.GetModifier(),element.GetKey());
        }

        static bool CompareElements( INARGTYPE element1, INARGTYPE element2 )
        {
            return Hash(element1)==Hash(element2);
        }

        static int CompareElementsOrdered( INARGTYPE element1, INARGTYPE element2 )
        {
            return Hash(element1)-Hash(element2);
        }
    };

    /**
    * @struct     IAcceleratorTarget
    * @brief      ���ټ����µĴ���ӿ�
    * 
    * Describe ��Ҫע����̼��ټ�������Ҫʵ�ֱ��ӿ�
    */
    struct IAcceleratorTarget
    {
        /**
         * OnAcceleratorPressed
         * @brief    
         * @param    const CAccelerator & accelerator --  ���µļ��ټ�
         * @return   bool -- ���ټ���������true
         * Describe  
         */    
        virtual bool OnAcceleratorPressed(const CAccelerator& accelerator) = 0;
    };

    /**
    * @struct     IAcceleratorMgr
    * @brief      ���ټ�����ӿ�
    * 
    * Describe
    */
    struct IAcceleratorMgr
    {
        // Register a keyboard accelerator for the specified target. If multiple
        // targets are registered for an accelerator, a target registered later has
        // higher priority.
        // Note that we are currently limited to accelerators that are either:
        // - a key combination including Ctrl or Alt
        // - the escape key
        // - the enter key
        // - any F key (F1, F2, F3 ...)
        // - any browser specific keys (as available on special keyboards)
        virtual void RegisterAccelerator(const CAccelerator& accelerator,
            IAcceleratorTarget* target)=NULL;

        // Unregister the specified keyboard accelerator for the specified target.
        virtual void UnregisterAccelerator(const CAccelerator& accelerator,
            IAcceleratorTarget* target)=NULL;

        // Unregister all keyboard accelerator for the specified target.
        virtual void UnregisterAccelerators(IAcceleratorTarget* target)=NULL;
    };
}//end of namespace SOUI
